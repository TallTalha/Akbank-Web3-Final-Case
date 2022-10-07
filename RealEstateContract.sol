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
        uint propertyID;  //Unique number so that each user can access their property in a sequential manner.
        address owner;  //the property owner's eth address.
        uint creationDate;  //the date of creation of the deed.
        uint changedDate; //the date the deed changed ownership.
        uint256 salePrice;  //Sale price of the property
        uint m2;  //square meter of the house
        bool forSale;  //Indicates whether the property is for sale.
        HomeAddress homeAddress;  //home address information

        uint advertID; //It will be necessary to cancel the advert.
    }
   
    struct HomeAddress {  //Address information of the property
        string country;
        string city;
        string addressLine;
        uint zipCode;
    }

    //Events
    event CreateAdvert( address indexed _owner,uint _advertID,uint _propertyID, uint256 _salePrice);
    event CancelAdvert( uint _advertID);
    event BuyProperty( address indexed OldOwner, address indexed NewOwner, uint changedDate);

    //Error
    error Deny(string reason);
    
    //State variables
    uint public advertCounter;  //Generates advert identities/IDs.
    PropertyInfo[] propertyInfos;  //Since a person can have more than one property "1 to many", I kept the information as an array. 
    PropertyInfo[] adverts; //Not every property will appear on the listing page so I created a separate structure for the listing page.
    

    //Mappings
    mapping (uint => mapping (address => uint))  advertInfo; // ( advert ID => (advert owner => advert propertyID ) )
    mapping (address => PropertyInfo[] ) properties; //Each property owner will have their own property list.

    
    constructor(){
        
    }

    //Only the deed is created. A function will be created to create a property advertisement.
    // Input Examples ; ["TR","Konya","Selcuklu",42250] 110  /  ["USA","NewYork","Brooklyn",1002] 225 / ["GER","Berlin","Kreuzberg",3002] 90 
    function createDeed(HomeAddress memory _homeAddress,uint _m2) external {
        properties[msg.sender].push(
        PropertyInfo( properties[msg.sender].length , msg.sender, block.timestamp, 0, 0, _m2,false, _homeAddress, 0 )
        );
        //Dynamized identity assignment with properties[msg.sender].length
        
    }
    function deleteDeed(uint _propertyID) onlyDeedOwner(_propertyID) external {
        delete  properties[msg.sender][_propertyID]; 
        //Solidity does not allow pop operation. Only the data in the specified index has been deleted.
        
        //Actually, there was a security vulnerability because the user still has permission to modify that data.
    }

    //Only property owners can post ads with the onlyDeedOwner Modifier.
    //In theory, those whose "forSale" variable is "true" will appear on the property listing page.
    function createAdvert(uint _propertyID, uint256 _salePrice) onlyDeedOwner(_propertyID) external {
        
        require(_salePrice > 0,"The selling price cannot be zero units."); //To prevent user error
        
        properties[msg.sender][_propertyID].salePrice = _salePrice;
        properties[msg.sender][_propertyID].forSale = true;

        adverts.push(properties[msg.sender][_propertyID]);

        properties[msg.sender][_propertyID].advertID = advertCounter;
        
        
        advertInfo[advertCounter][msg.sender] = _propertyID;

        emit CreateAdvert(msg.sender, advertCounter , _propertyID , _salePrice);//Logging the data.

        advertCounter +=1;
    }
    
    //In theory, those whose "forSale" variable is "true" will appear on the property listing page.
    function changeForSale(uint _propertyID, bool _state) onlyDeedOwner(_propertyID) external {
        properties[msg.sender][_propertyID].forSale = _state;
    }
    function changeSalePrice(uint _propertyID, uint256 _salePrice) onlyDeedOwner(_propertyID) external {
        properties[msg.sender][_propertyID].salePrice = _salePrice;
    }

    function cancelAdvert(uint _propertyID) onlyDeedOwner(_propertyID) external {
        
        properties[msg.sender][_propertyID].salePrice = 0;//Sale price reset.
        properties[msg.sender][_propertyID].forSale = false;//It is blocked from listing by setting the forSale value to false.
        
        delete  adverts[ properties[msg.sender][_propertyID].advertID ];//advert is deleted.
        
        emit CancelAdvert( properties[msg.sender][_propertyID].advertID );//The deleted data logged.
        
        properties[msg.sender][_propertyID].advertID = 0; //advertID reset. 
        //-1 would be better but we assigned an uint type.
    }

    function getPropertyInfo(uint _propertyID) onlyDeedOwner(_propertyID) external view returns(PropertyInfo memory){
        return properties[msg.sender][_propertyID];
    }
    
    function getForSaleProperty(uint _advertID) external view returns( PropertyInfo memory){
        require(_advertID < adverts.length, "Invalid advert id.");
        return adverts[_advertID];
    }
    function getSalePrice(uint _advertID) external view returns(uint){
        require(_advertID < adverts.length, "Invalid advert id.");
        return adverts[_advertID].salePrice;
    }

    //onlyCustomer Modifier provides = > property owners cannot buy their own property. / exp: 5000000000000000000 wei
    function buyProperty(uint _advertID) onlyCustomer(_advertID) external payable {
        
       
        require(msg.value == adverts[_advertID].salePrice, "You must pay the sale price."); 
        
        uint256 bal = adverts[_advertID].salePrice; //temporary variable.
        address oldOwner = adverts[_advertID].owner; //temporary variable.
        
        properties[msg.sender].push(properties[oldOwner][advertInfo[_advertID][oldOwner]]);
        
        uint index = properties[msg.sender].length - 1 ;
        properties[msg.sender][index].owner = msg.sender; //Owner is changed.
        properties[msg.sender][index].changedDate = block.timestamp ; //Specifies when the property changes owner.
        properties[msg.sender][index].salePrice = 0;  //Sale price reset.
        properties[msg.sender][index].forSale = false;  //It is blocked from listing by setting the forSale value to false.

        delete  properties[oldOwner][ advertInfo[_advertID][oldOwner] ]; //The deed structure of the former owners is deleted.
        delete  adverts[_advertID];//old advert is deleted.
        
        payable(oldOwner).transfer(bal); //Payment realized.

        emit BuyProperty(oldOwner,msg.sender,block.timestamp); //Logging the data.
    }

    //Modifiers
    modifier onlyDeedOwner(uint _propertyID){
        require(properties[msg.sender].length > 0,"You do not have any title deeds.");
        require(properties[msg.sender].length > _propertyID,"There is no title deed for this property identity.");
        _;
    }
    modifier onlyCustomer(uint _advertID){
        require(msg.sender !=  adverts[_advertID].owner ,"You are not authorized.");
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