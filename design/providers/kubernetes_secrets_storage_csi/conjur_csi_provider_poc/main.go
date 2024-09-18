package main

import (
	"bytes"
	"context"
	"crypto/tls"
	"encoding/base64"
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"net"
	"net/http"
	"net/url"
	"os"
	"os/signal"
	"strings"
	"syscall"

	"github.com/cyberark/conjur-api-go/conjurapi"
	"sigs.k8s.io/secrets-store-csi-driver/provider/v1alpha1"

	"google.golang.org/grpc"
)

const params = `
{
	"account": "some-org",
	"applianceUrl": "https://conjur.some-org.com",
	"authnLogin": "path/to/some-policy/some-host",
	"authnUrl": "https://conjur-auth.some-org.com",
	"cACertPath": "path/to/tls/cert",
	"csi.storage.k8s.io/ephemeral": "true",
	"csi.storage.k8s.io/pod.name": "app",
	"csi.storage.k8s.io/pod.namespace": "csi",
	"csi.storage.k8s.io/pod.uid": "89702199-a5f7-4c9b-a8e9-ffe644f7c2e9",
	"csi.storage.k8s.io/serviceAccount.name": "default",
	"csi.storage.k8s.io/serviceAccount.tokens": "{\"conjur\":{\"token\":\"eyJhbGciOiJSUzI1NiIsImtpZCI6ImpTdDRJbXhEZGJMVTM2LWxnemxzZ3dzRFRVdHUyUTZObndka2FINlo4TDQifQ.eyJhdWQiOlsibm90LXZhdWx0Il0sImV4cCI6MTY4OTcwMDAxMywiaWF0IjoxNjg5Njk2NDEzLCJpc3MiOiJodHRwczovL2t1YmVybmV0ZXMuZGVmYXVsdC5zdmMuY2x1c3Rlci5sb2NhbCIsImt1YmVybmV0ZXMuaW8iOnsibmFtZXNwYWNlIjoiY3NpIiwicG9kIjp7Im5hbWUiOiJhcHAiLCJ1aWQiOiI4OTcwMjE5OS1hNWY3LTRjOWItYThlOS1mZmU2NDRmN2MyZTkifSwic2VydmljZWFjY291bnQiOnsibmFtZSI6ImRlZmF1bHQiLCJ1aWQiOiI4Yjc5YzQ5Zi00NzlmLTRlN2UtYWRhYS1mMGI0YjE0NzkwZGIifX0sIm5iZiI6MTY4OTY5NjQxMywic3ViIjoic3lzdGVtOnNlcnZpY2VhY2NvdW50OmNzaTpkZWZhdWx0In0.rQJgkfKlpMjNVCIKIbU5DjECuK1F5Ma-AgNcreQlFLI5DYR8IwFjKYclV5daN7qOR1Uhi2ejL6CHlUIXa2fHSLr9lhxFiuwGMu1yCh46UaztSb9zUuAurmjAzfj3we07hA3REn9jX5ZK3uvUXMDW6G3n71VYkLEBF8X_cAMgnsChXe_VbPgx879CjjVZuLbBWFxlIueXjqbx3fLUzpTgPGacr3i9g3Q4o_cn3h8XscjkG-CXEmq5FF3I_Lof6MG5rZHWS7IwImEe4y6LI0KkEzETWki1Dg-msPL6gIPI9C7syUD5n_Q5EJQ76Z8vcIXf-8huLoIAo3f46KYXDF-usg\",\"expirationTimestamp\":\"2023-07-18T17:06:53Z\"}}",
	"policyPath": "path/to/some-policy/with-secrets",
	"secretProviderClass": "database-credentials",
	"secrets": "- db_username: \"db/username\" # relative to policyPath, otherwise if it starts with / then it is absolute\n- db_password: \"db/password\"\n"
}
`

const csiProviderName = "conjur"
const keyParamsCSITokens = "csi.storage.k8s.io/serviceAccount.tokens"

func main() {
	socketPath := flag.String("socket", "/provider/conjur.sock", "Path to the socket")
	flag.Parse()

	s, err := NewConjurCSIProviderServer(*socketPath)
	if err != nil {
		log.Fatalf("Failed to create CSI provider server: %v", err)
	}

	go func() {
		if err := s.Start(); err != nil {
			log.Fatalf("Failed to start CSI provider server: %v", err)
		}
	}()

	log.Printf("Conjur CSI provider server started. Socket path: %s\n", *socketPath)

	// Wait for termination signals to gracefully stop the server
	stop := make(chan os.Signal, 1)
	signal.Notify(stop, syscall.SIGINT, syscall.SIGTERM)
	<-stop

	s.Stop()
}

type ConjurCSIProviderServer struct {
	grpcServer *grpc.Server
	listener   net.Listener
	socketPath string
	returnErr  error
	errorCode  string
}

// NewConjurCSIProviderServer returns a csi-provider grpc server
func NewConjurCSIProviderServer(socketPath string) (*ConjurCSIProviderServer, error) {
	server := grpc.NewServer()
	s := &ConjurCSIProviderServer{
		grpcServer: server,
		socketPath: socketPath,
	}
	v1alpha1.RegisterCSIDriverProviderServer(server, s)
	return s, nil
}

func (m *ConjurCSIProviderServer) Start() error {
	var err error
	m.listener, err = net.Listen("unix", m.socketPath)
	if err != nil {
		return fmt.Errorf("failed to start listener: %w", err)
	}

	return m.grpcServer.Serve(m.listener)
}

func (m *ConjurCSIProviderServer) Stop() {
	m.grpcServer.GracefulStop()
}

// Mount implements provider csi-provider method
func (m *ConjurCSIProviderServer) Mount(ctx context.Context, req *v1alpha1.MountRequest) (*v1alpha1.MountResponse, error) {
	var attrib, secret map[string]string
	var filePermission os.FileMode
	var err error

	log.Printf("Mount request: %+v\n", req)

	if m.returnErr != nil {
		return &v1alpha1.MountResponse{}, m.returnErr
	}
	if err = json.Unmarshal([]byte(req.GetAttributes()), &attrib); err != nil {
		return nil, fmt.Errorf("failed to unmarshal attributes, error: %w", err)
	}
	if err = json.Unmarshal([]byte(req.GetSecrets()), &secret); err != nil {
		return nil, fmt.Errorf("failed to unmarshal secrets, error: %w", err)
	}
	if err = json.Unmarshal([]byte(req.GetPermission()), &filePermission); err != nil {
		return nil, fmt.Errorf("failed to unmarshal file permission, error: %w", err)
	}
	if len(req.GetTargetPath()) == 0 {
		return nil, fmt.Errorf("missing target path")
	}

	var tokens map[string]map[string]string

	if err := json.Unmarshal([]byte(attrib[keyParamsCSITokens]), &tokens); err != nil {
		log.Fatalf("failed to unmarshal attributes, error: %e", err)
	}

	workloadServiceAccountToken := tokens[csiProviderName]["token"]

	testSecretId := "secretVar"

	secretValuesById, err := getConjurSecrets(workloadServiceAccountToken, []string{testSecretId})
	if err != nil {
		return &v1alpha1.MountResponse{}, err
	}

	files := []*v1alpha1.File{
		{
			Path:     "secret1.txt",
			Mode:     777,
			Contents: secretValuesById[testSecretId],
		},
	}
	objects := []*v1alpha1.ObjectVersion{
		{
			Id:      testSecretId,
			Version: "1",
		},
	}

	return &v1alpha1.MountResponse{
		ObjectVersion: objects,
		Error: &v1alpha1.Error{
			Code: m.errorCode,
		},
		Files: files,
	}, nil
}

// Version implements provider csi-provider method
func (m *ConjurCSIProviderServer) Version(ctx context.Context, req *v1alpha1.VersionRequest) (*v1alpha1.VersionResponse, error) {
	return &v1alpha1.VersionResponse{
		Version:        "v1alpha1",
		RuntimeName:    csiProviderName,
		RuntimeVersion: "0.0.1",
	}, nil
}

func getConjurSecrets(token string, secretIds []string) (map[string][]byte, error) {
	// TODO: get the values below from request params
	baseURL := "https://conjur-conjur-oss.conjur.svc.cluster.local"
	authnId := "authn-jwt/kube"
	account := "default"
	identity := "host/host1"

	requestUrl, err := url.Parse(baseURL)
	if err != nil {
		return nil, err
	}

	requestUrl = requestUrl.JoinPath(authnId, account, url.PathEscape(identity), "authenticate")

	data := url.Values{}
	data.Set("jwt", string(token))

	transport := &http.Transport{
		TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
	}

	client := &http.Client{Transport: transport}

	req, err := http.NewRequest("POST", requestUrl.String(), bytes.NewBufferString(data.Encode()))
	if err != nil {
		return nil, err
	}

	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	req.Header.Set("Accept-Encoding", "base64")

	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	bodyContents, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	n, err := base64.StdEncoding.Decode(bodyContents, bodyContents)
	if err != nil {
		return nil, err
	}

	bodyContents = bodyContents[:n]

	conjur, err := conjurapi.NewClientFromToken(conjurapi.Config{Account: account, ApplianceURL: baseURL}, string(bodyContents))
	if err != nil {
		return nil, err
	}
	conjur.SetHttpClient(client)

	var secretValuesById = map[string][]byte{}
	secretValuesByFullId, err := conjur.RetrieveBatchSecrets(secretIds)
	if err != nil {
		return nil, err
	}

	prefix := fmt.Sprintf("%s:variable:", account)
	for k, v := range secretValuesByFullId {
		secretValuesById[strings.TrimPrefix(k, prefix)] = v
	}
	return secretValuesById, nil
}
