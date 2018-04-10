pragma solidity ^0.4.21;
import "github.com/oraclize/ethereum-api/oraclizeAPI_0.5.sol";
import "github.com/Arachnid/solidity-stringutils/src/strings.sol";

contract owned {
    address public owner;
    function owned() public {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}
contract SecureToken{
    string public name;
    string public symbol;
    uint8 public decimals = 4;
    uint256 public totalSupply;
    
    uint256  private activeUsers;
    
    address[9] phonebook = [0x3dc9E794EeA03FA621f071554D1781AD790aab37,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0];
    
    mapping (address => uint256) public balanceOf;
    mapping (address => uint256) public accountID;
    mapping (uint256 => address) public accountFromID;
    mapping (address=>bool) public isRegistered;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event TransferNeo(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Log(string t);
    event Log32(bytes32);
    event LogA(address);

    function SecureToken(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = 9*totalSupply/10;
        uint i;
        for(i=0;i<9;i++){
            balanceOf[phonebook[i]] = totalSupply/90;
        }
        name = tokenName;
        symbol = tokenSymbol;
    }
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
    function registerAccount(address user)internal{
        if(!isRegistered[user]){
            isRegistered[user] = true;
            activeUsers+=1;
            accountID[user] = activeUsers;
            accountFromID[activeUsers] = user;
        }
    }
    function registerAccountExternal()external{
        registerAccount(msg.sender);
    }
    
}
contract NP is owned, SecureToken, usingOraclize {
    using strings for *;
    uint256 public buyPrice;
    address private GameContract;
    address private EPLAY;
    
    string private XBSQueryURL;
    string public message;
    
    address cb;
    
    mapping (address => bool) public frozenAccount;
    event FrozenFunds(address target, bool frozen);
    
    bool callbackran=false;
//----------------------------------------------CONSTRUCTOR-----------------------------------------------//
    function NP(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    )SecureToken(initialSupply, tokenName, tokenSymbol) public payable{
        //oraclize_setProof(proofType_TLSNotary);
        registerAccount(owner);
        uint i;
        for(i=0;i<9;i++){
            registerAccount(phonebook[i]);
        }
    }
//-------------------------------------------MODIFIERS-------------------------------------------------------//
    modifier registered {
        require(isRegistered[msg.sender]);
        _;
    }
    modifier isGame {
        require(msg.sender == GameContract);
        _;
    }
    modifier isAfterRelease{
        require(block.timestamp>1525550400);
        _;
    }
    modifier isEPLAY{
        require(msg.sender == EPLAY);
        _;
    }
//--------------------------------------TYPECAST FUNCTIONS---------------------------------------------------//
    function appendUintToString(string inStr, uint v)internal pure returns (string str) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(48 + remainder);
        }
        bytes memory inStrb = bytes(inStr);
        bytes memory s = new bytes(inStrb.length + i);
        uint j;
        for (j = 0; j < inStrb.length; j++) {
            s[j] = inStrb[j];
        }
        for (j = 0; j < i; j++) {
            s[j + inStrb.length] = reversed[i - 1 - j];
        }
        str = string(s);
    }
    function makeXID(uint v)private pure returns (string str){
        str = appendUintToString("XID",v);
    }
    function stringToUint(string s)internal pure returns (uint256 result) {
        bytes memory b = bytes(s);
        uint256 i;
        result = 0;
        for (i = 0; i < b.length; i++) {
            uint256 c = uint256(b[i]);
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
    }
//--------------------------------------ACCESSOR FUNCTIONS--------------------------------------------------//
    function getbuyPrice()public view returns(uint256){
        return(buyPrice);
    }
    function isOwner()public{
        if(owner==msg.sender)emit Log("Owner");
        else{
            emit Log("Not Owner");
        }
    }
    function getXQU()internal view returns(string){
        return(XBSQueryURL);
    }
    function getGC()external view returns(address){
        return(GameContract);
    }
//----------------------------------------MUTATOR FUNCTIONS-------------------------------------------//
    function setPrice(uint256 newBuyPrice) onlyOwner public {
        buyPrice = newBuyPrice;
    }
    function setGC(address newAddy) onlyOwner public{
        GameContract = newAddy;
    }
    function setXQU(string newQU) onlyOwner public{
        XBSQueryURL=newQU;
    }
    function setEPLAY(address newAddy) onlyOwner public{
        EPLAY = newAddy;
    }
//----------------------------------------TRANSFER FUNCTIONS------------------------------------------//
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                               
        require (balanceOf[_from] >= _value);               
        require (balanceOf[_to] + _value > balanceOf[_to]);
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);
        balanceOf[_from] -= _value;                         
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }
    function buy() payable public isAfterRelease {
        require(owner.balance >0);
        uint256 multiplier;
        if(block.timestamp < 1525636800){
            multiplier = 150;
        }else if(block.timestamp < 1526155200){
            multiplier = 140;
        }else if(block.timestamp <1526760000){
            multiplier = 120;
        }else if(block.timestamp <1527364800){
            multiplier = 115;
        }else if(block.timestamp <1527969600){
            multiplier = 105;
        }else{
            multiplier=100;
        }
        uint amount = msg.value / buyPrice;
        _transfer(owner, msg.sender, multiplier*amount/100);
    }
    function buyExternally(address user,uint value) payable external isAfterRelease isEPLAY{
        require(owner.balance >0);
        uint256 multiplier;
        if(block.timestamp < 1525636800){
            multiplier = 150;
        }else if(block.timestamp < 1526155200){
            multiplier = 140;
        }else if(block.timestamp <1526760000){
            multiplier = 120;
        }else if(block.timestamp <1527364800){
            multiplier = 115;
        }else if(block.timestamp <1527969600){
            multiplier = 105;
        }else{
            multiplier=100;
        }
        uint amount = value / buyPrice;
        _transfer(owner,user,multiplier*amount/100);
    }
//-----------------------------------------------OTHER FUNCTIONS---------------------------------------//
    function freezeAccount(address target, bool freeze) onlyOwner external {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    function burnFrom(address _from, uint256 _value) internal returns (bool success) {
        require(balanceOf[_from] >= _value);
        balanceOf[_from] -= _value;
        totalSupply -= _value;
        emit Burn(_from, _value);
        return true;
    }
    function burn(uint256 val)public{
        burnFrom(msg.sender,val);
    }
    function burnFromContract(address user,uint256 val)external isGame{
        burnFrom(user,val);
    }
    function transfer(address to, uint256 val)public payable{
        _transfer(msg.sender,to,val);
    }
//-------------------------------------------SISTER TOKEN FUNCTIONS-------------------------------------//
    function sendLink(string xid,string Nb,string Na)internal{
        string memory url = getXQU();
        string memory data = strConcat(strConcat("{\"XID\":\"",xid,"\",\"NB\":\"",Nb),strConcat("\",\"NA\":\"",Na,"\"}"));
        emit Log(data);
        oraclize_query("URL",url,data);
    }
    function link(address EtherAddress,string NeoAddress)external registered {
        if(balanceOf[EtherAddress]==0)revert();
        string memory xid = makeXID(accountID[EtherAddress]);
        string memory nBalance = appendUintToString("B",balanceOf[EtherAddress]);
        sendLink(xid,nBalance,NeoAddress);
    }   
    function __callback(bytes32 myid, string result)public{
       if(msg.sender != oraclize_cbAddress()){
           cb = 0x0;
           message = "it reverted";
           revert();
       }
       callbackran=true;
       message = result;
       //result should come back as "XID{id}B{balance}"
       strings.slice memory id = (result.toSlice()).beyond("XID".toSlice());
       strings.slice memory nbalance = (result.toSlice()).beyond("B".toSlice());
       burnFrom(accountFromID[stringToUint(id.toString())],stringToUint(nbalance.toString()));
       myid;
    }
    function check() public{
        if(callbackran){
            emit Log("CallbackRan");
            emit LogA(cb);
            emit Log(message);
        }else{
            emit Log("CallbackNoRan");
            emit Log(message);
        }
    }
}
