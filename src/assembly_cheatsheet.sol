// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract Slot0_And_Slot1{
    /* slot: 0 */ uint256 internal _counter; 
    /* slot: 1 */ bytes4 internal _hexInfo;
    
}

/// @author 0xAtharva
/// @notice practical usage cheatsheet of inline assembly (educational purposes only)
contract Cheatsheet is Slot0_And_Slot1 {
    /* slot: 2 */ address internal alice;
    /* slot: 3 */ string internal _name = "counting now"; 
    /* slot: 4 */ bool internal _pause; 
    
    /* slot: 5 */ uint256[] internal _a = [71,2,3];
    /* slot: 6 */ mapping(address => uint256) register;


    
    function setCounter_sol(uint256 val) public {
        _counter = val;
    }

    function setCounter_asm(uint256 val) public {
        assembly {
            sstore(0x00, val)
        }
    }

    function getCounter_sol() view public returns(uint256) {
        return _counter;
    }

    //reading and returning uint256 from storage
    function getCounter_asm() view public returns(uint256 result) {
        assembly{
            result := sload(0)
        }
    }

    //reading and returning strings from storage
    function name() view public returns(string memory) {
        assembly{
            let n := sload(2)
            let memptr := mload(0x40)
            mstore(memptr,0x20)
            mstore(add(memptr,0x20),12)
            mstore(add(memptr,0x40),n)
            return(memptr,0x60)
        }
    }

    // memory array sum (loops)
    // notice that memory arrays are fixed size
    function arraySum(uint256[] memory a) pure public returns(uint256) {
        assembly {
            let sum
            let l := mload(a)
            for { let i:= 0 } lt(i,l) { i := add(i,1) }{
                sum := add(sum, mload(add(add(a,0x20),mul(i,0x20))))
            }
            let memptr := mload(0x40)
            mstore(memptr,sum)
            return(memptr,0x20)
        }
    }
    
    /********************* EVM architecture notes **************************/
    /*
    1. bits 
        1. a single transistor thats on(1) or off(0)
        2. bit is the smallest piece of information in computer architecture 



    2. bytes
        1. a group of 8 transistors
        2. this group of transistors together represent a certain character.
        3. byte is the fundamental unit of data in computers



    3. words
        1. a group of 32 bytes
        2. EVM operates on words



    4. endian formats
        1. the order in which bytes are arranged within larger datatypes in computer memory
        2. big-endian : english way  ,      little-endian : arabic way
        3. EVM operates on 32 byte words, which are stored in big-endian format



    5. character encodings
        1. an encoding scheme to represent characters ASCII, UTF-8



    6. datatypes
        1. strict containers for data that maintain sanity in the code
        2. a certain size
        3. a certain interpretation
        4. bundled methods



    7. floating points in computers
                base 10 : 1000   100   10   1   1/10   1/100   1/1000
                base 2  :   8     4    2    1    1/2    1/4     1/8
        1. computers are naturally base 2 (transistors can only be On/Off)
        2. representing base 10 decimals with underlying as base 2 is tricky. Computers need to
        construct base 10 decimals using base 2 components and there are unexpected decimal
        arithmetic outputs in computers so solidity has got rid of floats.
        3. To mimic decimal behaviour just use scaled values by the required decimal places you need



    8. overflow underflow
        1. valuation (in terms of binary values) : (base)**following
        2. this is a common problem that occurs when 
        the output is out of the limits of the datatype container size.



    9. literals
        1. fixed values embedded in the code
        2. carry a certain interpretation
        3. types
            1. decimal literals : underscores allowed, NeX allowed
            2. hexadecimal literals : start with 0x
            3. address literals : hexadecimals that follow eip55 address checksum
            4. string literals : "....."
            5. boolean literal : true/false
            6. unicode literal : unicode"....."



    [10] data location, opcodes and inline assembly(yul)
        1. memory 
            - structure : byte addressable array
            - scratch space 
                0x00 : a 32 byte slot 
                0x20 : a 32 byte slot 
            - Free memory pointer
                0x40 : this contains location to a free memory
            - zero slot
                0x60 : zero slot, used as default value for uninitialized variables
            - opcodes : mload, mstore
            - inline assembly : mload(address), mstore(address, value) 
            - trivia 
                - temporary, only for duration of tx
                - cheap
                - function scoped
        2. storage 
            - structure
                - mapping of 32-byte keys(storage-slots) to a 32-byte values
                - storage slots start at slot 0
            - opcodes : sload, sstore
            - inline assembly : sload(slot), sstore(slot, value)
            - trivia
                - permanent
                - expensive 
                - globally avilable
                [-] If the next value can fit into the same slot (determined by type), it is right-aligned in the same slot, else it is stored in the next slot.
                - Immutable and constant values are not written to storage, therefore they do not increment the storage slot count.
                - Storage slots of a parent contract precedes the child in the order of inheritance.
                - mapping value slot : keccak256(abi.encode(key,declaration slot))
                - arrays : A dynamically sized array stores the current length in its slot, then its elements are stored sequentially from Keccak-256 hash of the slot number.
                - byte arrays and strings : Byte arrays and strings are stored the same way as other dynamic arrays unless the length is 31 or less.
                Then it is packed into one slot and the right-most byte is occupied by two times the length.
        3. calldata 
            - structure : same as memory but read-only
            - opcodes : calldatasize, calldatacopy, calldataload
            - inline assembly : 
            - trivia
                - takes in the external calldata input to the functions
        4. transient storage
            - persists across the txn
            - opcodes : tload, tstore
            - inline assembly : 
        5. stack
            - inputs to opcodes are popped from the stack
            - results of opcodes are pushed to the stack
            - opcodes : pushN
            - stack has a program counter: where in the bytecode the next execution command is
        6. addresses in comp arch
            1 addresses are numbers
                - memeory address : points to a single byte
                - storage address : points to a word (32 bytes)
                - stack address : points to a slot (32 bytes)
            2 all addresses start with zero (0x00)
        [7] opcodes 
            1 details
                - SSTORE 100
                - SLOAD 100
                - MSTORE 3
                - MSTORE8 3
                - MLOAD  3
                - MCOPY 3
                - CALLDATALOAD 3
                - CALLDATACOPY 3
                - TLOAD 100
                - TSTORE 100
                - CALL 100
                - DELEGATECALL 100
                - STATICCALL 100
                - REVERT 0
                - RETURN 0
                - CREATE 32000
                - CREATE2 32000
                - CALLER 2
                - GAS 2
                - TIMESTAMP 2
                - NUMBER 2
                - PREVRANDAO 2
                - GASLIMIT 2
                - CHAINID 2
                - SELFBALANCE 5
                - BASEFEE 2
                - ADD 3
                - SUB 3
                - MUL 5
                - DIV 5
                - LT 3
                - GT 3
                - EQ 3
                - SHR 3
                - SHL 3
                - LOG0 375
                - LOG1 750
                - LOG2 1125
                - LOG3 1500
                - LOG4 1875
                - PUSH0 2
                - PUSHx 3 : push the next x bytes(1-32) of data to the stack
                - DUPx 3 : duplicate the xth(1-16) value on the stack
                - POP 2 : remove item from the stack 
                - EXTCODESIZE 100 : get size of an account's code
                - JUMP 8
                - JUMPI 10
                - JUMPDEST 1 
            2 trivia
                - 1 byte in lenght (two hex characters long)
                - opcodes may take input from stack or have it hardcoded in contract bytecode
                - there is warm and cold about opcode operations
                - the gas pricing is dynamic
        [8] inline assembly(yul)
            syntax
                - assembly{...}
                - :=  assignment
                - no use of semicolons
                - yul manages stack for us, devs manage memory and storage*/
            // Components ------------------------------------------------------------------//
            // variables -*-*-*-*-
            // - all variables are local declared using let (no strict types in assembly cuz assembly is dealing with bytes, 
            //   yul is making up those literals for us)
            // - variables declared inside assembly scope are not available outside
            // - variables declared inside function but outside assemlby scope are avilable inside
            function variables() pure public {
                assembly{
                    let memptr
                    let x := 100
                }
            }

            // mload -*-*-*-*-
            // - reads the memory at given location
            function mload() pure public { 
                assembly {
                    let memptr := mload(0x40)
                }
            }

            // mstore -*-*-*-*-
            // - stores the value at given location
            function mstore() pure public {
                assembly {
                    let memptr := mload(0x40)
                    mstore(memptr, 1000)
                    mstore(0x40, add(memptr,0x20))
                }
            }

            // mstore8 -*-*-*-*-
            // - stores the 1 byte value at given location
            function mstore8() pure public {
                assembly {
                    let memptr := mload(0x40)
                    mstore8(memptr, "$")
                    mstore(0x40, add(memptr,0x01))
                }
            }

            // calldataload(p) -*-*-*-*-
            // - reads calldata(32 bytes) from given location 
            function calldataload(string calldata message) pure public {
                assembly {
                    let param := calldataload(0x04)
                }
            }

            // calldatacopy(t,f,s) -*-*-*-*-
            // - copy s bytes from calldata at position f to mem at position t
            // - think of it as hybrid of calldataload and mstore
            function calldatacopy(string calldata) pure public {
                assembly {
                    let memptr := mload(0x40)
                    calldatacopy(memptr, 0, 32)
                }
            }

            // sload(p) -*-*-*-*-
            // - reads the storage at given location 
            function sload() view public {
                assembly {
                    let success := sload(0)
                }
            }

            // sstore(p,v) -*-*-*-*-
            // - store the value at given location
            function sstore() public {
                assembly {
                    sstore(5, 1005)
                }
            }

            // return(p,s) -*-*-*-*-
            // - end execution, return data mem[p…(p+s))
            // - return can only read from memory
            function Return() view public {
                assembly {
                    let memptr := mload(0x40)
                    mstore(memptr, sload(5))
                    let returnPosition := memptr
                    mstore(0x40, add(memptr, 0x20))
                    return(returnPosition, 0x20)
                }
            }

            // logs (events) 
            // - The first topic is always the Keccak-256 hash of the event signature.
            // - Non-indexed topics are logged by storing them in memory and passing to the log instruction a pointer to the start 
            //   of the data and the length of the data.
            // - log0, log1, log2, log3, log4
            function logs() pure public {
                assembly {
                    // log0(0x00, 0x00)
                    // log1(0x00, 0x00, 0x00)
                    // log2()
                    // log3()
                    // log4()
                }
            }

            // errors 
            // - consist of a four byte error selector and the error data.
            // - reverts data only from the memory
            // - revert
            function Revert() pure public {
                assembly {
                    // revert()
                }
            } 
            
            // Globals ------------------------------------------------------------------------------//
            // types And Literals -*-*-*-*-
            // - no strict types everything is let
            // - all of the literals form solidity can be used here
            function typesAndLiterals() pure public {
                assembly {
                    let x := 82                                             // Decimal
                    let y := 0x2A                                           // Hexadecimal
                    let addr := 0xdAC17F958D2ee523a2206206994597C13D831ec7  // address
                    let z := "abc"                                          // String (stored as bytes)
                    let success := true                                     // bool
                }
            }

            // keccak256(mem[p,0x20]) 
            // - start reading data from the address provided
            function keccak256hash() pure public {
                assembly {
                    let memptr := mload(0x40)
                    mstore(memptr, "msg")
                    let hash := keccak256(memptr, 0x20)
                    mstore(0x40, add(memptr, 0x20))
                }
            }

            // eq 
            // - returns 1 if equal, else 0
            function eq(uint256 x, uint256 y) public pure returns(bool result) {
                assembly {
                    result := eq(x,y)
                }
            }

            // add 
            function add(uint256 x, uint256 y) public pure returns(uint256 result) {
                assembly {
                    result := add(x,y)
                }
            }
            
            // sub 
            function sub(uint256 x, uint256 y) public pure returns(uint256 result) {
                assembly {
                    result := sub(x,y)
                }
            }

            // mul 
            function mul(uint256 x, uint256 y) public pure returns(uint256 result) {
                assembly {
                    result := mul(x,y)
                }
            }

            // div 
            function div(uint256 x, uint256 y) public pure returns(uint256 result) {
                assembly {
                    result := div(x,y)
                }
            }

            // mod 
            function mod(uint256 x, uint256 y) public pure returns(uint256 result) {
                assembly {
                    result := mod(x,y)
                }
            }

            // exp 
            function exp(uint256 x, uint256 y) public pure returns(uint256 result) {
                assembly {
                    result := exp(x,y)
                }
            }
            
            // signextend 
            function signextend(uint256 x, uint256 y) public pure returns(uint256 result) {
                assembly {
                    result := signextend(x,y)
                }
            }

            // gt 
            function gt(uint256 x, uint256 y) public pure returns(bool result) {
                assembly {
                    result := gt(x,y)
                }
            }

            // lt 
            function lt(uint256 x, uint256 y) public pure returns(bool result) {
                assembly {
                    result := lt(x,y)
                }
            }

            // slt 
            function slt(uint256 x, uint256 y) public pure returns(bool result) {
                assembly {
                    result := slt(x,y)
                }
            }
            
            // sgt 
            function sgt(uint256 x, uint256 y) public pure returns(bool result) {
                assembly {
                    result := sgt(x,y)
                }
            }

            // iszero 
            function iszero(uint256 x) public pure returns(bool result) {
                assembly {
                    result := iszero(x)
                }
            }

            // and 
            function and(uint256 x, uint256 y) public pure returns(uint256 result) {
                assembly {
                    result := and(x,y)
                }
            }

            // or 
            function or(uint256 x, uint256 y) public pure returns(uint256 result) {
                assembly {
                    result := or(x,y)
                }
            }

            // xor 
            function xor(uint256 x, uint256 y) public pure returns(uint256 result) {
                assembly {
                    result := xor(x,y)
                }
            }

            // not 
            function not(uint256 x) public pure returns(uint256 result) {
                assembly {
                    result := not(x)
                }
            }

            // shl 
            function shl(uint256 x, uint256 y) public pure returns(uint256 result) {
                assembly {
                    result := shl(x,y)
                }
            }

            // shr 
            function shr(uint256 x, uint256 y) public pure returns(uint256 result) {
                assembly {
                    result := shr(x,y)
                }
            }

            // sar 
            function sar(uint256 x, uint256 y) public pure returns(uint256 result) {
                assembly {
                    result := sar(x,y)
                }
            }

            // ecrecover -*-*-*-*-
            // - returns the address recovered from the signature
            // - ecrecover(h, v, r, s)
            function Ecrecover() pure public returns(address result){
                assembly {
                    // let memptr := mload(0x40)
                    // mstore(memptr, 0x00)
                    // mstore(add(memptr,0x20), 0x00)
                    // mstore(add(memptr,0x40), 0x00)
                    // mstore(add(memptr,0x60), 0x00)
                    // result := ecrecover(memptr, 0x00, 0x00, 0x00)
                }
            }

            // call 
            // - returns 1 if success, else 0
            // - call(forward all gas, target address, eth value, input pointer, input size, out pointer, output size)
            function call() public {
                assembly {
                    let success := call(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)

                    if iszero(success) {
                        returndatacopy(0, 0, returndatasize())
                        revert(0, returndatasize())
                    }
                }
            }

            // delegatecall 
            // - returns 1 if success, else 0
            // - delegatecall(forward all gas, target address, input pointer, input size, out pointer, output size)
            function delegatecall() public {
                assembly {
                    let success := delegatecall(0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
                }
            }
            
            // extcodesize 
            function extcodesize() view public {
                assembly {
                    let size := extcodesize(0x00)
                }
            }

            // gas remaining 
            function gas() view public {
                assembly {
                    let _gas := gas()
                }
            }

            function caller() view public {
                assembly {
                    let _caller := caller()
                }
            }
            // create 
            // - 
            function create(bytes memory code) public returns (address) {
                address deployed;
                assembly {
                    deployed := create(0, add(code, 0x20), mload(code))
                    if iszero(deployed) {
                        revert(0, 0)
                    }
                }
                return deployed;
            }

            // create2 
            // - 
            function create2() public {
                assembly {
                    let success := create2(0x00, 0x00, 0x00, 0x00)
                }
            }

            // for loop 
            function forLoop() pure public {
                assembly {
                    for { let i := 0 } lt(i, 10) { i := add(i, 1) } {
                        // loop body 
                    }
                }
            }

            // if else 
            // - 
            function ifElse() pure public {
                assembly {
                    let a := 10
                    if eq(a, 10) {
                        // if body
                    } {
                        // notice that there is no mention of else in else block
                    }
                }
            }

            // switch 
            // - 
            function switchCase() pure public {
                assembly {
                    let k := 0
                    switch k
                    case 0 {
                        // Handle case 0
                    }
                    default {
                        // Default case
                    }
                }
            }


    /*[11] Gas
        1. what is gas
            - a resource metering system
            - gas is a commodity like petrol is for bike 
        2. why gas
            - system resources can be abused
            - gas solves halting problem(prevent DOS attacks on the chain)
        3. how its used
            [ ] from where is gas bought
            - gas has to be bought in ETH
            - each opcode consumes certain gas for execution
            - gas has to be purchased in the same transaction for execution
            - tx gets priority depending on the gas it is willing to pay for execution of the txn
        4. terms and definitions
            - gas : a unit of resource usage
            - gas price : the rate of 1 gas in ethers
            - gas cost : how much gas is required for tx to execute
            - gas fee : the metering of 'txn' in gas
            - base fee : base fee for the 'txn'
            - priority fee : the fee for bypassing the queue
            - max fee : max gas you are willing to spend on the txn
            - gas refund : remaining gas gets repaid (if its left after execution)
            [ ] EIP1559
            - blockGasLimit : 
            - gasLimit : max amt of gas a txn can consume
        5. trivia 
            - each block has a gasLimit (total gas that can be consumed by all the txns in the that block) 
            - gas prices change depending on market demand for blockspace
            - if delete operation executes, the freed resource gas is refunded to sender of txn
            - if tx fails, gas used is used (it can't be refunded)
            - there are certain gasless trxns (may be called meta txns)
            - only writes consume gas, reads are free
            - gasfees is collected by validators
            - call() : sneds 63/64 gas forward the cross contract execution
            - gas()/gasleft() is globally available to check for gas status of the txn
            - L2 impacts on gas costs
        




    12. accounts
        1. Contract Accounts ( no keys, only address )
            - codeHash
            - storageRoot
            - nonce
            - balance
        2. User accounts ( pvt key, public key and address )
            - nonce
            - balance
        3. trivia
            - accounts are represented by address
                - Contract account address generated from CREATE2 opcode
                - User account address generated from public key




    13. txns and messages
        1. trxns 
            - a special message that is initiated by user accounts
            - components : RLPdata<nonce, gasPrice, startGas, to, value, data>, v, r, s
            - after the txn is validated and included in the block, a txn reciept is generated
            - offchain systems can prove these reciepts to collect on-chain info.
        2. messages
            - has a context : msg.sender, msg.value, msg.data, msg.sig
            - messages are the base of communication in ethereum



    14. mempool
        - txns are submitted here
        - external observers can scan for txns here
        - it is the battle ground for price wars




    15. blocks
        - block.timestamp
        - block.chainid
        - block.number
        - blockhash(block.number)
        - block.basefee
        - block.gaslimit
        - gasleft()
        - block.difficulty
        - block.blobbasefee
        - block.coinbase
        - block.prevrandao



    [16] consensus
        - proof of stake
        - validators
        - slashing
        - block reorg
        - finality



    [17] L1, L2s and scalability trilemma
        1. scalability trilemma 
            - three poles : speed, cost, security
            - optimize for the best of three worlds
        2. L1 L2 seperation 
            - to imporve on gas costs
        3. special upgrades
            - danksharding 
    */
}