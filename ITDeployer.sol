pragma solidity ^0.5.2;

interface ITDeployer {
    function newToken(address, string calldata, string calldata, address) external returns(address);
    function setFactoryAddress(address) external;
    function getFactoryAddress() external view returns(address);
}