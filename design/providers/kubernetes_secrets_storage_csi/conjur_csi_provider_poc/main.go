package main

import (
	"context"
	"encoding/json"
	"fmt"
	"net"
	"os"

	"sigs.k8s.io/secrets-store-csi-driver/provider/v1alpha1"

	"google.golang.org/grpc"
)

func main() {
	s, err := NewConjurCSIProviderServer("/provider/conjur.sock")
	if err != nil {
		panic(err)
	}

	err = s.Start()
	if err != nil {
		panic(err)
	}

}

type ConjurCSIProviderServer struct {
	grpcServer *grpc.Server
	listener   net.Listener
	socketPath string
	returnErr  error
	errorCode  string
	objects    []*v1alpha1.ObjectVersion
	files      []*v1alpha1.File
}

// NewConjurCSIProviderServer returns a csi-provider grpc server
func NewConjurCSIProviderServer(socketPath string) (*ConjurCSIProviderServer, error) {
	server := grpc.NewServer()
	s := &ConjurCSIProviderServer{
		grpcServer: server,
		socketPath: socketPath,
		files: []*v1alpha1.File{
			{
				Path:     "secret1.txt",
				Mode:     777,
				Contents: []byte("some secret from Conjur"),
			},
		},
		objects: []*v1alpha1.ObjectVersion{
			{
				Id:      "path/to/secret1/in/conjur",
				Version: "1",
			},
		},
	}
	v1alpha1.RegisterCSIDriverProviderServer(server, s)
	return s, nil
}

func (m *ConjurCSIProviderServer) Start() error {
	var err error
	m.listener, err = net.Listen("unix", m.socketPath)
	if err != nil {
		return err
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

	fmt.Println("request", req)

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
	return &v1alpha1.MountResponse{
		ObjectVersion: m.objects,
		Error: &v1alpha1.Error{
			Code: m.errorCode,
		},
		Files: m.files,
	}, nil
}

// Version implements provider csi-provider method
func (m *ConjurCSIProviderServer) Version(ctx context.Context, req *v1alpha1.VersionRequest) (*v1alpha1.VersionResponse, error) {
	return &v1alpha1.VersionResponse{
		Version:        "v1alpha1",
		RuntimeName:    "conjur",
		RuntimeVersion: "0.0.1",
	}, nil
}
