// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.13 and less than 0.9.0
pragma solidity ^0.8.13;

//@dev https://app.patika.dev/JessFlexx , https://github.com/TallTalha

//Akbank Web3 Practicum Final Case
/*
Extra task: Develop a front-end that runs your smart contract. 
(I couldn't complete the extra mission.)
But then I can add an image in the readme.md file that answers 
what the draft design would be like if I could front end.
*/

/*
In this contract, users will create their title deeds on the blockchain, and if they want to sell these properties later,
they will be able to advertise or buy properties that are open for sale.
*/

contract RealEstateContract{
    
    //Structs
    struct PropertyInfo{
        uint propertyID;
        address owner; //the property owner's eth address.
        uint creationDate; //the date of creation of the deed.
        uint changedDate; //the date the deed changed ownership.
        uint256 salePrice; //Sale price of the property
        uint m2; //square meter of the house
        bool forSale; //Indicates whether the property is for sale.
        HomeAddress homeAddress; //home address information

        uint advertID; //It will be necessary to cancel the advert.
    }
    
    struct HomeAddress { //Address information of the property
        string province;
        string district;
        string fullAddress;
        uint zipCode;
    }

    //Events
    event CreateAdvert( address indexed _owner,uint _advertID,uint _propertyID, uint256 _salePrice);
    event CancelAdvert( uint _advertID);
    event BuyProperty( address indexed OldOwner, address indexed NewOwner,uint _propertyID, uint changedDate);

    //Error
    error Deny(string reason);
    
    //State variables
    uint idCounter;
    uint advertID = 100;
    
    PropertyInfo[] propertyInfos;//Since a person can have more than one property, I kept the information as an array. "1 to many"
    
    
    //Mappings
    mapping (uint => address) advertInfo; // ( advert ID => advert owner )

    
    constructor(){
        
    }
    //Only the deed is created. A function will be created to create a property advertisement.
    function createDeed(HomeAddress memory _homeAddress,uint _m2) external {
        propertyInfos.push(PropertyInfo(idCounter,msg.sender,block.timestamp,0,0,_m2,false,_homeAddress,0));
        idCounter += 1;
    }

    //Only property owners can post ads with the onlyOwner Modifier.
    //In theory, those whose "forSale" variable is "true" will appear on the property listing page.
    function createAdvert(uint256 _salePrice, uint _propertyID) onlyOwner(_propertyID) external {
        
        require(_salePrice > 0,"The selling price cannot be zero units."); //To prevent user error
        
        propertyInfos[_propertyID].salePrice = _salePrice;
        propertyInfos[_propertyID].forSale = true; 
        
        propertyInfos[_propertyID].advertID = advertID;
        
        advertInfo[advertID] = msg.sender;
        emit CreateAdvert(msg.sender,advertID,_propertyID,_salePrice);//Logging the data.
        
        advertID +=1;
    }
    
    //In theory, those whose "forSale" variable is "true" will appear on the property listing page.
    function changeForSale(uint _propertyID, bool _state) onlyOwner(_propertyID) external {
        propertyInfos[_propertyID].forSale = _state;
    }
    function changeSalePrice(uint _propertyID, uint256 _salePrice) onlyOwner(_propertyID) external {
        propertyInfos[_propertyID].salePrice = _salePrice;
    }

    function cancelAdvert(uint _propertyID) onlyOwner(_propertyID) external {
        
        propertyInfos[_propertyID].salePrice = 0;//Sale price reset.
        propertyInfos[_propertyID].forSale = false;//It is blocked from listing by setting the forSale value to false.
        
        delete advertInfo[propertyInfos[_propertyID].advertID];//advertID delete.
        emit CancelAdvert(propertyInfos[_propertyID].advertID);//The deleted data logged.
        
        propertyInfos[_propertyID].advertID = 0; //advertID reset.
    }

    function getPropertyInfo(uint _propertyID) external view returns(PropertyInfo memory){
        return propertyInfos[_propertyID];
    }
    function getAdvertInfo(uint _advertID) external view returns(address){
        require(_advertID > 0,"Advert ID must be bigger than 99."); //The min id is 100.
        return advertInfo[ _advertID ];
    }

    //onlyCustomer Modifier provides = > property owners cannot buy their own property.
    function buyProperty(uint _propertyID) onlyCustomer(_propertyID) external payable {
        
        require(true == propertyInfos[_propertyID].forSale, "Not available for sale."); //Checks if the house is open for sale.
        require(msg.value == propertyInfos[_propertyID].salePrice, "You must pay the sale price."); 
        
        uint256 bal = propertyInfos[_propertyID].salePrice; //temporary variable.
        address oldOwner = propertyInfos[_propertyID].owner; //temporary variable.
        
        propertyInfos[_propertyID].changedDate = block.timestamp;
        propertyInfos[_propertyID].owner = msg.sender;//Owner changed.
        propertyInfos[_propertyID].salePrice = 0;//Sale price reset.
        propertyInfos[_propertyID].forSale = false;//It is blocked from listing by setting the forSale value to false.

        payable(oldOwner).transfer(bal);

        emit BuyProperty(oldOwner,msg.sender,_propertyID,block.timestamp);
    }

    //Modifiers
    modifier onlyOwner(uint _propertyID){
        require(msg.sender == propertyInfos[_propertyID].owner,"You are not authorized.");
        _;
    }
    modifier onlyCustomer(uint _propertyID){
        require(msg.sender !=  propertyInfos[_propertyID].owner ,"You are not authorized.");
        _;
    }

    //No currency can be transferred to the contract except for functions.
    receive() external payable {
        revert Deny("No direct payment.");

    }
    fallback() external payable {
        revert Deny("No direct payment.");
    }
}