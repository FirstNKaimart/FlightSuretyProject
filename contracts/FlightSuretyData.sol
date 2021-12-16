// SPDX-License-Identifier: MIT

pragma solidity ^0.5.0;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false
    mapping(address => uint256) private authorizedContracts;

    // Airline variables
    struct Vote {
        mapping(address => bool) addressVoted;
        uint256 voteCount;
    }

    struct Airline {
        address wallet; // address of airline 
        bool isRegistered;
        string name;
        uint256 funded;
        // mapping(string => bool) flights;
        // mapping(string => mapping(address => bool)) flightPassenger;
        Vote votes;
    }
    mapping(address => Airline) private airlines;
    uint256 public constant INSURANCE_PRICE_LIMIT = 1 ether;
    uint256 public constant MINIMUM_FUNDS = 10 ether;

    // Multiparty variables
    uint8 private constant MULTIPARTY_MIN_AIRLINES = 4;
    uint256 public airlinesCount = 0;

    // Passenger variables
    struct Passenger {
        address wallet;
        mapping(string => uint256) purchasedInsuranceAmount;
        uint256 balance;
    }
    mapping(address => Passenger) private passengers;
    address[] public passengerAddresses;
    // mapping(address => bool) public isPassenger;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor() public 
    {
        contractOwner = msg.sender;
        authorizedContracts[msg.sender] = 1;

        airlines[msg.sender].wallet = msg.sender;
        airlines[msg.sender].isRegistered = true;
        airlines[msg.sender].name = "UdacityAir";
        airlines[msg.sender].funded = MINIMUM_FUNDS;
        airlines[msg.sender].votes.addressVoted[msg.sender] = true;
        airlines[msg.sender].votes.voteCount = 1;
        // airlines[msg.sender].flights["UDA001"] = true;
        airlinesCount++;
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() 
    {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    /**
    * @dev Modifier that requires the calling App contract has been authorized
    */
    modifier requireIsCallerAuthorized()
    {
        require(authorizedContracts[msg.sender] == 1, "Caller is not an authorized contract");
        _;
    }


    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() 
                            public 
                            view 
                            returns(bool) 
    {
        return operational;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus (bool mode) external requireContractOwner 
    {
        operational = mode;
    }

    function authorizeCaller( address contractAddress) external requireContractOwner
    {
        authorizedContracts[contractAddress] = 1;
    }

     function isAuthorized(address contractAddress) external view returns(bool)
    {
        return(authorizedContracts[contractAddress] == 1);
    }

    function deauthorizeCaller( address contractAddress) external requireContractOwner
    {
        delete authorizedContracts[contractAddress];
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function isActive(address _airlineAddr ) public view returns(bool) {
        return(airlines[_airlineAddr].funded >= MINIMUM_FUNDS);
    }

    function isRegistered ( address _airlineAddr ) public view returns(bool) {
        return( airlines[_airlineAddr].isRegistered );
    }

    function registerAirline( address _airlineAddr, string calldata _name) 
    external 
    requireIsOperational
    requireIsCallerAuthorized
    returns (bool)
    {
        require(_airlineAddr != address(0), "Airline Address is not valid.");
        require(!airlines[_airlineAddr].isRegistered, "Airline is already registered.");

        if(airlinesCount < MULTIPARTY_MIN_AIRLINES){
            airlines[_airlineAddr].wallet = _airlineAddr;
            airlines[_airlineAddr].isRegistered = true;
            airlines[_airlineAddr].name = _name;
            airlines[_airlineAddr].funded = 0;
            airlines[_airlineAddr].votes.addressVoted[msg.sender] = true;
            airlinesCount++;
        } else {
            require(voteAirline(_airlineAddr), "An error occured in voting operation");
        }
        return (true);
    }

    function voteAirline (address _airlineAddr) internal requireIsOperational returns(bool) {
        bool votingOK = false;
        require(airlines[_airlineAddr].votes.addressVoted[msg.sender] == false, "Vote already casted by this address.");
        airlines[_airlineAddr].votes.addressVoted[msg.sender] = true;
        airlines[_airlineAddr].votes.voteCount++;

        if(airlines[_airlineAddr].votes.voteCount >= airlinesCount.div(2)) {
            airlines[_airlineAddr].isRegistered = true;
            airlinesCount++;
        }
        votingOK = true;
        return votingOK;

    }

    function getAirlineVotes(address _airlineAddr) public view returns(uint256 votes) {
        return (airlines[_airlineAddr].votes.voteCount);
    }

    // function registerFlight (address _airlineAddr, string memory _flightCode ) external requireIsOperational requireIsCallerAuthorized returns(bool) {
    //     bool registerFlightOK = false;
    //     require(msg.sender == airlines[_airlineAddr].wallet,"Unauthorized access");
    //     require(airlines[_airlineAddr].isRegistered, "Airline not registered");
    //     require(airlines[_airlineAddr].funded == 10 ether,"Airline is not funded");

    //     airlines[_airlineAddr].flights[_flightCode] = true;
    //     registerFlightOK = true;
    //     return registerFlightOK;
    // }


   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy(string calldata _flightCode)external payable requireIsOperational
    {
        // require(airlines[_airlineAddr].flights[_flightCode] == true,"Flight is not Registered");
        require(msg.sender == tx.origin, "Only EOA, Contracts not allowed");
        require(msg.value > 0, "Must be more than zero to buy a flight insurance");
        require(msg.value <= INSURANCE_PRICE_LIMIT, "Must be below or equal to 1 ether");

        if(!checkIfExist(msg.sender)){
            passengerAddresses.push(msg.sender);
        }
        if (passengers[msg.sender].wallet != msg.sender) {
            //airlines[_airlineAddr].flightPassenger[_flightCode][msg.sender] = true;
            passengers[msg.sender].wallet = msg.sender;
            passengers[msg.sender].purchasedInsuranceAmount[_flightCode] = msg.value;
            passengers[msg.sender].balance = 0;
        } else {
            passengers[msg.sender].purchasedInsuranceAmount[_flightCode] = msg.value;
        }
    }

    function checkIfExist(address passenger) internal view returns(bool inExist){
        inExist = false;
        for (uint256 i = 0; i < passengerAddresses.length; i++) {
            if (passengerAddresses[i] == passenger) {
                inExist = true;
                break;
            }
        }
        return inExist;
    }

    /**
     *  @dev Insurance payouts to insurees
    */
    function pay(string calldata _flightCode )external requireIsOperational
    {
        for (uint256 i = 0; i < passengerAddresses.length; i++) {
            if(passengers[passengerAddresses[i]].purchasedInsuranceAmount[_flightCode] != 0) {
                uint256 savedBalance = passengers[passengerAddresses[i]].balance;
                uint256 payedPrice = passengers[passengerAddresses[i]].purchasedInsuranceAmount[_flightCode];
                passengers[passengerAddresses[i]].purchasedInsuranceAmount[_flightCode] = 0;
                passengers[passengerAddresses[i]].balance = savedBalance + payedPrice + payedPrice.div(2);
            }
        }
    }

    function getAmountToPay() external view returns (uint256) {
        return passengers[msg.sender].balance;
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
     function withdraw
                            (
                                address payable _insuredPassenger
                            )
                            public
                            requireIsOperational
                            returns (uint256, uint256, uint256, uint256, address, address)
    {
        require(_insuredPassenger == tx.origin, "Contracts not allowed");
        require(msg.sender == _insuredPassenger,"Unauthorized access");
        require(passengers[_insuredPassenger].balance > 0, "The company didn't put any money to be withdrawed by you");

        uint256 contractBalance = address(this).balance;
        uint256 passengerBalance = passengers[_insuredPassenger].balance;
        require(address(this).balance > passengerBalance, "The contract does not have enough funds to pay the credit");
        
        passengers[_insuredPassenger].balance = 0;
        _insuredPassenger.transfer(passengerBalance);
        uint256 finalBalance = passengers[_insuredPassenger].balance;
        return (contractBalance, passengerBalance, address(this).balance, finalBalance, _insuredPassenger, address(this));
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund() public requireIsOperational payable
    {
        require(msg.sender == tx.origin, "Contracts not allowed");
        require(airlines[msg.sender].isRegistered, "Airline is not registered");
        require(msg.value >= MINIMUM_FUNDS, "Insufficient funding amount");

        uint256 currentFunds = airlines[msg.sender].funded;
        airlines[msg.sender].funded = currentFunds.add(msg.value);
        
    }

    function isAirline (address _airline)
                        external
                        view
                        returns (bool) {
        if (airlines[_airline].wallet == _airline) {
            return true;
        } else {
            return false;
        }
    }

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function() 
                            external 
                            payable 
    {
        fund();
    }


}

