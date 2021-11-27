// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MultisigWallet{
    address private owner;
    address[] private authorized;
    mapping (address => bool) private authorized_bool;
    mapping (address => uint256) private depositedAmount;
    uint256 private txId;
    uint256 constant MIN_SIG = 2;
    mapping(address => bool) isSigned;

    struct Transaction{
        uint256 txId;
        address sender;
        address receiver;
        uint256 amount;
        bool isSigned;
        uint256 signitureAmount;
    }
    mapping(uint256 => Transaction) transactions;
    uint256[] _pendingTransactions;

    event Deposit(address indexed sender, uint256 value);
    event TransactionCreated(uint256 txId, address sender, address receiver, uint256 amount);
    event TransactionSigned(uint256 txId, address signer);
    event TransactionCompleted(uint256 txId, address sender, address receiver, uint256 amount);

    
    constructor(address _owner, address[] memory _authorized) {
        require(_owner != address(0), "Invalid owner address");
        owner = _owner;
        for (uint256 i = 0; i < _authorized.length; i++) {
            require(_authorized[i] != address(0));
            require(!authorized_bool[_authorized[i]]);
            authorized[i] = _authorized[i];
            authorized_bool[_authorized[i]] = true;
        }
    }
    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }
    modifier validOwner{
        require(msg.sender == owner || authorized_bool[msg.sender] == true, "Only owner or authorized user can call this function");
        _;
    }
    function addOwner(address _newOwner) public onlyOwner{
        authorized.push(_newOwner);
        authorized_bool[_newOwner] = true;
    }
    function deposit(uint256 _amount) public payable{
        payable(address(this)).transfer(_amount);
        depositedAmount[msg.sender] += _amount;
        emit Deposit(msg.sender, _amount);
    }
    function withdraw(uint256 _amount, address _authorisedAccount) public {
        require(authorized_bool[_authorisedAccount]);
        require(msg.sender == owner);
        require(_amount <= depositedAmount[_authorisedAccount]);
        payable(msg.sender).transfer(_amount);
    }
    function balanceOf() public view returns (uint256){
        return address(this).balance;
    }

    function createTransaction(address receiver, uint256 amount) public validOwner{
        require(address(this).balance >= amount);
        uint256 _transactionId = txId ++;
        Transaction memory _transaction;
        _transaction.txId = _transactionId;
        _transaction.sender = msg.sender;
        _transaction.receiver = receiver;
        _transaction.amount = amount;

        _pendingTransactions.push(_transactionId);
        emit TransactionCreated(_transactionId, msg.sender, receiver, amount);
    }
    function getPendingTransactions() view public returns(uint256[] memory){
        return _pendingTransactions;
    }

    function signTransaction(uint256 _transactionId, address _signer) public validOwner{
        _signer = msg.sender;
        require(address(0) != _signer, "Empty signer address");
        require(_signer != transactions[_transactionId].sender, "Signer is the sender");
        require(!transactions[_transactionId].isSigned, "Transaction already signed");

        isSigned[_signer] = true;
        transactions[_transactionId].isSigned = isSigned[_signer];
        transactions[_transactionId].signitureAmount += 1;
        emit TransactionSigned(txId, _signer);
    }
    function completeTransaction(uint256 _transactionId) public validOwner{
        require(transactions[_transactionId].isSigned, "Transaction not signed");
        require(address(this).balance >= transactions[_transactionId].amount, "Not enough balance");
        if (transactions[_transactionId].signitureAmount >= MIN_SIG){
            address sender = transactions[_transactionId].sender;
            address receiver = transactions[_transactionId].receiver;
            uint256 amount = transactions[_transactionId].amount;
            payable(receiver).transfer(amount);
            deletePendingTransaction(_transactionId);
            emit TransactionCompleted(txId, sender, receiver, amount);
        }
    }
    function deletePendingTransaction(uint256 _transactionId) public validOwner{
        for (uint i = _transactionId; i < _pendingTransactions.length; i++){
            _pendingTransactions[i] = _pendingTransactions[i+1];
        }
        _pendingTransactions.pop();
        delete transactions[_transactionId];
    }
    // In the case where the owner of the contract wants to withdraw all the money but has lost the private key
    // All accounts must agree upon this
    function withdrawAllButLost(address[] memory _authorised) public payable{
        require(_authorised.length == authorized.length);
    }
}
