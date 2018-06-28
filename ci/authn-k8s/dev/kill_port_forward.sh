#!/bin/bash

kill $(cat run/port_forward_inventory.pid)
rm -f run/port_forward_inventory.pid
kill $(cat run/port_forward_conjur.pid)
rm -f run/port_forward_conjur.pid
