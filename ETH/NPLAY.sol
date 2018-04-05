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
contract TokenERC20{
    string public name;
    string public symbol;
    uint8 public decimals = 4;
    uint256 public totalSupply;
    
    mapping (address => uint256) public balanceOf;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event TransferNeo(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Log(string t);
    event Log32(bytes32);
    event LogA(address);

    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
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
}
contract NP is owned, TokenERC20, usingOraclize {
    using strings for *;
    struct request {
        address from;
        address to;
        uint256 action;
        uint256 value;
    }
    uint256 public sellPrice;
    uint256 public buyPrice;
    address private GameContract;
    
    string private XBSQueryURL;
    string private r;
    
    address cb;
    
    uint256  private activeUsers;
    mapping (address => bool) public frozenAccount;
    mapping (address => uint256) private accountID;
    mapping (uint256 => address) private accountFromID;
    mapping (address=>bool) public isRegistered;
    event FrozenFunds(address target, bool frozen);
    
    bool callbackran=false;

    function NP(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    )TokenERC20(initialSupply, tokenName, tokenSymbol) public payable{
        //oraclize_setProof(proofType_TLSNotary);
        isRegistered[owner] = true;
        activeUsers=1;
        accountID[owner] = 1;
        accountFromID[1] = owner;
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
        if(msg.sender==owner)emit Log("Owner");
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
    function getsellPrice()external view returns(uint256){
        return(sellPrice);
    }
//----------------------------------------MUTATOR FUNCTIONS-------------------------------------------//
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner external {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }
    function setGC(address newAddy) onlyOwner public{
        GameContract = newAddy;
    }
    function setXQU(string newQU) onlyOwner public{
        XBSQueryURL=newQU;
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
    function buy() payable external {
        uint amount = msg.value / buyPrice;
        _transfer(owner, msg.sender, amount);
    }

    function sell(uint256 amount) external payable {
        require(owner.balance >= amount * sellPrice);
        _transfer(msg.sender, owner, amount);
    }
//-----------------------------------------------OTHER FUNCTIONS---------------------------------------//
    function registerAccount()external{
        if(!isRegistered[msg.sender]){
            isRegistered[msg.sender] = true;
            activeUsers+=1;
            accountID[msg.sender] = activeUsers;
            accountFromID[activeUsers] = msg.sender;
        }
    }
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
    function burn(uint256 val) external{
        burnFrom(msg.sender,val);
    }
    function burnFromContract(address user,uint256 val)external isGame{
        burnFrom(user,val);
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
           revert();
       }
       callbackran=true;
       //result should come back as "XID:::nbalance"
       strings.slice memory id = (result.toSlice()).beyond("XID".toSlice()).until(":::".toSlice());
       strings.slice memory nbalance = (result.toSlice()).beyond(":::B".toSlice());
       uint256 ID = stringToUint(id.toString());
       cb = accountFromID[ID];
       r = result;
       burnFrom(accountFromID[ID],stringToUint(nbalance.toString()));
       emit Log32(myid);
    }
    function check() public{
        if(callbackran){
            emit Log("CallbackRan");
            emit LogA(cb);
            emit Log(r);
        }else{
            emit Log("CallbackNoRan");
        }
    }
}
