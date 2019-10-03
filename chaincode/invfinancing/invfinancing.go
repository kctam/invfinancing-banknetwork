/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

/*
 * The sample smart contract for documentation topic:
 * Writing Your First Blockchain Application
 */

package main

/* Imports
 * 4 utility libraries for formatting, handling bytes, reading and writing JSON, and string manipulation
 * 2 specific Hyperledger Fabric specific libraries for Smart Contracts
 */
import (
	"encoding/json"
	"errors"
	"fmt"
	"strconv"

	"github.com/hyperledger/fabric/core/chaincode/shim"
	sc "github.com/hyperledger/fabric/protos/peer"
)

// Define the Smart Contract structure
type SmartContract struct {
}

// Define the car structure, with 4 properties.  Structure tags are used by encoding/json library
type Invoice struct {
	InvoicedAmount int `json:"invoicedamount"`
	BorrowedAmount int `json:"borrowedamount"`
}

func (s *SmartContract) Init(APIstub shim.ChaincodeStubInterface) sc.Response {
	return shim.Success(nil)
}

func (s *SmartContract) Invoke(APIstub shim.ChaincodeStubInterface) sc.Response {

	// Retrieve the requested Smart Contract function and arguments
	function, args := APIstub.GetFunctionAndParameters()
	// Route to the appropriate handler function to interact with the ledger appropriately
	if function == "initInv" {
		return s.initInv(APIstub, args)
	} else if function == "requestLoan" {
		return s.requestLoan(APIstub, args)
	} else if function == "queryInv" {
		return s.queryInv(APIstub, args)
	}

	return shim.Error("Invalid Smart Contract function name.")
}

func (s *SmartContract) initInv(APIstub shim.ChaincodeStubInterface, args []string) sc.Response {
	var err error
	var invoice *Invoice
	var invoiceBytes []byte
	var invoiceKey string
	var amount int

	if len(args) != 3 {
		err = errors.New(fmt.Sprintf("Incorrect number of arguments. Expecting 3: {Company, InvoiceNo, InvoicedAmount}. Found %d", len(args)))
		return shim.Error(err.Error())
	}

	// check integer on InvoicedAmount
	amount, err = strconv.Atoi(string(args[2]))
	if err != nil {
		return shim.Error(err.Error())
	}

	invoiceKey = args[0] + "-" + args[1]
	// check if not empty
	invoiceBytes, err = APIstub.GetState(invoiceKey)
	if err != nil {
		return shim.Error(err.Error())
	}
	if len(invoiceBytes) != 0 {
		err = errors.New(fmt.Sprintf("Record found for company %s and invoice %s", args[0], args[1]))
		return shim.Error(err.Error())
	}

	invoice = &Invoice{amount, 0}
	invoiceBytes, _ = json.Marshal(invoice)

	err = APIstub.PutState(invoiceKey, invoiceBytes)
	if err != nil {
		return shim.Error(err.Error())
	}

	return shim.Success(nil)

}

func (s *SmartContract) requestLoan(APIstub shim.ChaincodeStubInterface, args []string) sc.Response {
	var err error
	var invoice *Invoice
	var invoiceBytes []byte
	var invoiceKey string
	var amount int

	if len(args) != 3 {
		err = errors.New(fmt.Sprintf("Incorrect number of arguments. Expecting 3: {Company, InvoiceNo, RequestedAmount}. Found %d", len(args)))
		return shim.Error(err.Error())
	}

	// check integer on InvoicedAmount
	amount, err = strconv.Atoi(string(args[2]))
	if err != nil {
		return shim.Error(err.Error())
	}

	invoiceKey = args[0] + "-" + args[1]
	// check not found
	invoiceBytes, err = APIstub.GetState(invoiceKey)
	if err != nil {
		return shim.Error(err.Error())
	}
	if len(invoiceBytes) == 0 {
		err = errors.New(fmt.Sprintf("Record not found for company %s and invoice %s", args[0], args[1]))
		return shim.Error(err.Error())
	}

	err = json.Unmarshal(invoiceBytes, &invoice)
	if err != nil {
		return shim.Error(err.Error())
	}

	if amount > (invoice.InvoicedAmount - invoice.BorrowedAmount) {
		err = errors.New(fmt.Sprintf("Amount %s requested exceeds credit limit", args[2]))
		return shim.Error(err.Error())
	}

	invoice.BorrowedAmount = invoice.BorrowedAmount + amount

	// save back the result
	invoiceBytes, _ = json.Marshal(invoice)
	err = APIstub.PutState(invoiceKey, invoiceBytes)
	if err != nil {
		return shim.Error(err.Error())
	}

	return shim.Success(nil)

}

func (s *SmartContract) queryInv(APIstub shim.ChaincodeStubInterface, args []string) sc.Response {
	var err error
	var invoice *Invoice
	var invoiceBytes []byte
	var invoiceKey string

	if len(args) != 2 {
		err = errors.New(fmt.Sprintf("Incorrect number of arguments. Expecting 2: {Company, InvoiceNo}. Found %d", len(args)))
		return shim.Error(err.Error())
	}

	invoiceKey = args[0] + "-" + args[1]
	// check not found
	invoiceBytes, err = APIstub.GetState(invoiceKey)
	if err != nil {
		return shim.Error(err.Error())
	}
	if len(invoiceBytes) == 0 {
		err = errors.New(fmt.Sprintf("Record not found for company %s and invoice %s", args[0], args[1]))
		return shim.Error(err.Error())
	}

	err = json.Unmarshal(invoiceBytes, &invoice)
	if err != nil {
		return shim.Error(err.Error())
	}

	return shim.Success(invoiceBytes)

}

func main() {

	// Create a new Smart Contract
	err := shim.Start(new(SmartContract))
	if err != nil {
		fmt.Printf("Error creating new Smart Contract: %s", err)
	}
}
