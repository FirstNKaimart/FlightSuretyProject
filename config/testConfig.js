
var FlightSuretyApp = artifacts.require("FlightSuretyApp");
var FlightSuretyData = artifacts.require("FlightSuretyData");
var BigNumber = require('bignumber.js');

var Config = async function(accounts) {
    
    // These test addresses are useful when you need to add
    // multiple users in test scripts
    let testAddresses = [
        "0x686C9fEf5A4ECB4b1411a71a3EF14F9BfD31C7Ef",
        "0xa62c7891F4b5B592504671de9Ce75CE81BDC156A",
        "0x2935EB9f25910cFC67E51FEfC41C4BEDc232085C",
        "0x430Bdc60654Ff10597B29ea4D3aF7903EF86817E",
        "0x04676a4025B3315f3C84BbB95FD4378F02BdeD9A",
        "0xc5AdDfAAE26Ae9bE63756a5aA4d7B2Ea855B5Dad",
        "0x53870027976A5BCdf6C523bBB5576782057d9Dd0",
        "0xdD5B1cDb8e7411aA0479A7fAe06Cd90d4B44A1C9",
        "0x8033f73c179cAe861684D294A993d490C5E344c2",
        "0x8731FA830fc564f9703053cD9197189E41010132",
        "0xA41f8316479B7cafbE524c11a7d334AcCd1cE4c6",
        "0x5F1f2deaAa5e205119b87b1a31C0C46C6B5C6Af6",
        "0x2EE7396c641c6a22Ab2aa5954eD59D77e0E6c070",
        "0x710aFf6e771e135C6c3FED1FdA727730e904f39f",
        "0x1cE0e94Abe43D079814a1e5862D82177c0b5f77A",
        "0x2B0681e298ec890dd5CC3BeEaC48240Aac8f2ce1",
        "0xe2EB9265a4167E84a3D4c584Bc923e78AFAa2AB7",
        "0x1ad397011D50F4afCB123c67b6830585d652E360",
        "0xcAa04c09281Cf2b50d62B10C6ad429C419ffdD28",
        "0xcAa04c09281Cf2b50d62B10C6ad429C419ffdD28",
    ];


    let owner = accounts[0];
    let firstAirline = accounts[1];
    let firstPassenger = accounts[8];
    
    let flightSuretyData = await FlightSuretyData.new();
    let flightSuretyApp = await FlightSuretyApp.new(flightSuretyData.address);

    
    return {
        owner: owner,
        firstAirline: firstAirline,
        firstPassenger: firstPassenger,
        weiMultiple: (new BigNumber(10)).pow(18),
        testAddresses: testAddresses,
        flightSuretyData: flightSuretyData,
        flightSuretyApp: flightSuretyApp
    }
}

module.exports = {
    Config: Config
};