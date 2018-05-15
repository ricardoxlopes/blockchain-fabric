package main

import (
	"fmt"
	"bytes"
	"encoding/json"
	"strconv"
	"github.com/hyperledger/fabric/core/chaincode/shim"
	pb "github.com/hyperledger/fabric/protos/peer"
)

// SimpleChaincode example simple Chaincode implementation
type SimpleChaincode struct {
}

func (t *SimpleChaincode) Init(stub shim.ChaincodeStubInterface) pb.Response {
	fmt.Println("Chaincode ex02 Init")
	
	args := stub.GetArgs()
	
	var healthRecordId, healthRecordData string
	var err error
	
	if len(args) != 2 && len(args) != 0 {
		return shim.Error("Incorrect number of arguments. Expecting 2")
	}

	// Initialize the chaincode
	healthRecordId = string(args[0])
	healthRecordData = string(args[1])

	if err != nil {
		return shim.Error("Expecting integer value for asset holding")
	}
	
	// Write the state to the ledger
	err = stub.PutState(healthRecordId, []byte(healthRecordData))
	if err != nil {
		return shim.Error(err.Error())
	}

	return shim.Success(nil)
}

func (t *SimpleChaincode) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	fmt.Println("ex02 Invoke")
	function, args := stub.GetFunctionAndParameters()
	if function == "invoke" {
		return t.invoke(stub, args)
	} else if function == "delete" {
		// Deletes an entity from its state
		return t.delete(stub, args)
	} else if function == "query" {
		return t.query(stub, args)
	} else if function == "rich_query" {
		return t.rich_query(stub, args[0])
	}

	return shim.Error("Invalid invoke function name. Expecting \"invoke\" \"delete\" \"query\"")
}

func (t *SimpleChaincode) invoke(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	var healthRecordId string          // Transaction ID
	var healthRecordData map[string]interface{}          // Transaction value
	var err error
	var newVar []byte;

	if len(args) != 1 {
	 	return shim.Error("Incorrect number of arguments. Expecting 1")
	}

	var healthRecord map[string]interface{};
	jsonValid, _ := strconv.Unquote(args[0])
	
    if err = json.Unmarshal([]byte(jsonValid), &healthRecord); err != nil {
        return shim.Error("Failed to UNMARSHAL")
	}
	// Perform the execution
	
	healthRecordId = healthRecord["Key"].(string);
	healthRecordData = healthRecord["Record"].(map[string]interface{});
	
	newVar, err = json.Marshal(healthRecordData)

	if err != nil {
    	return shim.Error("Failed to Marshal")
	}
	
	// Write the state back to the ledgerS
	err = stub.PutState(healthRecordId, []byte(newVar))
	
	if err != nil {
		return shim.Error(err.Error())
	}

	return shim.Success(nil)
}

// Deletes an entity from state
func (t *SimpleChaincode) delete(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting 1")
	}

	A := args[0]

	// Delete the key from the state in ledger
	err := stub.DelState(A)
	if err != nil {
		return shim.Error("Failed to delete state")
	}

	return shim.Success(nil)
}

// query callback representing the query of a chaincode
func (t *SimpleChaincode) query(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	var healthRecordId string
	var err error

	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting health record ID query")
	}

	healthRecordId = args[0]

	// Get the state from the ledger
	Avalbytes, err := stub.GetState(healthRecordId)
	if err != nil {
		jsonResp := "{\"Error\":\"Failed to get state for " + healthRecordId + "\"}"
		return shim.Error(jsonResp)
	}

	if Avalbytes == nil {
		jsonResp := "{\"Error\":\"Nil amount for " + healthRecordId + "\"}"
		return shim.Error(jsonResp)
	}

	// jsonResp := "{\"Health record ID\":\"" + healthRecordId + "\",\"DATA\":\"" + string(Avalbytes) + "\"}"
	// fmt.Printf("Query Response:%s\n", jsonResp)
	return shim.Success(Avalbytes)
}

func (t *SimpleChaincode) rich_query(stub shim.ChaincodeStubInterface, queryString string) pb.Response {
    fmt.Printf("- getQueryResultForQueryString queryString:\n%s\n", queryString)

	var err error

	resultsIterator, err:= stub.GetQueryResult(queryString)
    defer resultsIterator.Close()
    if err != nil {
        return shim.Error("Incorrect")
    }
    // buffer is a JSON array containing QueryRecords
    var buffer bytes.Buffer
    buffer.WriteString("[")
    bArrayMemberAlreadyWritten:= false
    for resultsIterator.HasNext() {
        queryResponse,
        err:= resultsIterator.Next()
        if err != nil {
            return shim.Error("Incorrect number of arguments. Expecting 2")
        }
        // Add a comma before array members, suppress it for the first array member
        if bArrayMemberAlreadyWritten == true {
            buffer.WriteString(",")
        }
        buffer.WriteString("{\"Key\":")
        buffer.WriteString("\"")
        buffer.WriteString(queryResponse.Key)
        buffer.WriteString("\"")
        buffer.WriteString(", \"Record\":")
        // Record is a JSON object, so we write as-is
        buffer.WriteString(string(queryResponse.Value))
        buffer.WriteString("}")
        bArrayMemberAlreadyWritten = true
    }
    buffer.WriteString("]")
	fmt.Printf("- getQueryResultForQueryString queryResult:\n%s\n", buffer.String())
	
	return shim.Success(buffer.Bytes())
}

func main() {
	err := shim.Start(new(SimpleChaincode))
	if err != nil {
		fmt.Printf("Error starting Simple chaincode: %s", err)
	}
}