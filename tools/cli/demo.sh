#!/bin/bash

# Demo script showing all features of the CP command processor system

cd "$(dirname "$0")"

echo "=========================================="
echo "CP Command Processor - Feature Demo"
echo "=========================================="
echo

echo "1. HELP AND VERSION"
echo "-------------------"
echo "$ ./main.sh --help"
./main.sh --help
echo
echo "$ ./main.sh --version"
./main.sh --version
echo

echo "2. BASIC COMMAND EXECUTION"
echo "--------------------------"
echo "$ ./main.sh cmd1"
./main.sh cmd1
echo

echo "3. NESTED COMMAND EXECUTION"
echo "---------------------------"
echo "$ ./main.sh sone foo"
./main.sh sone foo
echo
echo "$ ./main.sh stwo ssx yaya"
./main.sh stwo ssx yaya
echo

echo "4. FALLBACK TO main.sh"
echo "----------------------"
echo "$ ./main.sh (no args)"
./main.sh
echo
echo "$ ./main.sh sone"
./main.sh sone
echo

echo "5. OPTIONS PARSING"
echo "------------------"
echo "$ ./main.sh sone foo -ab --my-value=\"test123\" target1"
./main.sh sone foo -ab --my-value="test123" target1
echo
echo "$ ./main.sh stwo ssx yaya -rp --threads=16 myaction"
./main.sh stwo ssx yaya -rp --threads=16 myaction
echo

echo "6. DIRECT SCRIPT EXECUTION"
echo "--------------------------"
echo "$ ./cmd/sone/foo.sh --help | head -15"
./cmd/sone/foo.sh --help | head -15
echo
echo "$ ./cmd/sone/bar.sh -qd --config=custom.conf"
./cmd/sone/bar.sh -qd --config=custom.conf
echo

echo "7. EXCLUSION BEHAVIOR"
echo "---------------------"
echo "$ ./main.sh sone const (should fail)"
./main.sh sone const 2>&1
echo
echo "$ ./main.sh sone statics (should fail)"
./main.sh sone statics 2>&1
echo

echo "=========================================="
echo "Demo Complete!"
echo "=========================================="
