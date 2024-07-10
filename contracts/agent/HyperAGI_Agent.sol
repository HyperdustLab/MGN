pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../utils/StrUtil.sol";
import "../HyperAGI_Roles_Cfg.sol";
import "../HyperAGI_Storage.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

abstract contract IERC1155 {
    function burn(address account, uint256 id, uint256 value) public {}
}

contract HyperAGI_Agent is OwnableUpgradeable {
    using Strings for *;
    using StrUtil for *;

    address public _rolesCfgAddress;
    address public _storageAddress;
    address public _agentPOPNFTAddress;
    address public _groundRodAddress;

    uint256[] private groundRodLevelKeys;
    mapping(uint256 => uint256) public _groundRodLevels;

    event eveSaveAgent(bytes32 sid);
    event eveRechargeEnergy(bytes32 sid, uint256 groundRodLevelId);
    event eveAgentAccount(address account, uint256 index);

    function initialize(address onlyOwner) public initializer {
        __Ownable_init(onlyOwner);
    }

    function setRolesCfgAddress(address rolesCfgAddress) public onlyOwner {
        _rolesCfgAddress = rolesCfgAddress;
    }

    function setStorageAddress(address storageAddress) public onlyOwner {
        _storageAddress = storageAddress;
    }

    function setAgentPOPNFTAddress(address agentPOPNFTAddress) public onlyOwner {
        _agentPOPNFTAddress = agentPOPNFTAddress;
    }

    function setGroundRodAddress(address groundRodAddress) public onlyOwner {
        _groundRodAddress = groundRodAddress;
    }

    function setContractAddress(address[] memory contractaddressArray) public onlyOwner {
        _rolesCfgAddress = contractaddressArray[0];
        _storageAddress = contractaddressArray[1];
        _agentPOPNFTAddress = contractaddressArray[2];
        _groundRodAddress = contractaddressArray[3];
    }

    function setGroundRodLevels(uint256[] memory tokenIds, uint256[] memory levels) public onlyOwner {
        for (uint i = 0; i < groundRodLevelKeys.length; i++) {
            delete _groundRodLevels[groundRodLevelKeys[i]];
        }

        groundRodLevelKeys = tokenIds;

        for (uint i = 0; i < tokenIds.length; i++) {
            _groundRodLevels[tokenIds[i]] = levels[i];
        }
    }

    function mint(uint256 tokenId, string memory avatar, string memory nickName, string memory personalization) public {
        require(IERC721(_agentPOPNFTAddress).ownerOf(tokenId) == msg.sender, "not owner");

        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);

        require(storageAddress.getUint(tokenId.toString()) == 0, "already minted");

        storageAddress.setUint(tokenId.toString(), 1);

        uint256 id = storageAddress.getNextId();

        bytes32 sid = generateUniqueHash(id);
        storageAddress.setBytes32Uint(sid, id);

        storageAddress.setUint(storageAddress.genKey("tokenId", id), tokenId);

        storageAddress.setString(storageAddress.genKey("avatar", id), avatar);

        storageAddress.setString(storageAddress.genKey("nickName", id), nickName);
        storageAddress.setString(storageAddress.genKey("personalization", id), personalization);

        storageAddress.setBytes32(storageAddress.genKey("sid", id), sid);

        if (!storageAddress.getBool(msg.sender.toHexString())) {
            storageAddress.setBool(msg.sender.toHexString(), true);
            storageAddress.setAddressArray("agentAccountList", address(this));
        }

        emit eveSaveAgent(sid);
    }

    function update(bytes32 sid, string memory avatar, string memory nickName, string memory personalization) public {
        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);

        uint256 id = storageAddress.getBytes32Uint(sid);

        require(id > 0, "not found");

        uint256 tokenId = storageAddress.getUint(storageAddress.genKey("tokenId", id));

        require(IERC721(_agentPOPNFTAddress).ownerOf(tokenId) == msg.sender, "not owner");

        storageAddress.setString(storageAddress.genKey("avatar", id), avatar);

        storageAddress.setString(storageAddress.genKey("nickName", id), nickName);
        storageAddress.setString(storageAddress.genKey("personalization", id), personalization);

        emit eveSaveAgent(sid);
    }

    function getAgent(bytes32 sid) public view returns (uint256, string memory, string memory, string memory, uint256) {
        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);

        uint256 id = storageAddress.getBytes32Uint(sid);

        require(id > 0, "not found");

        return (
            storageAddress.getUint(storageAddress.genKey("tokenId", id)),
            storageAddress.getString(storageAddress.genKey("avatar", id)),
            storageAddress.getString(storageAddress.genKey("nickName", id)),
            storageAddress.getString(storageAddress.genKey("personalization", id)),
            storageAddress.getUint(storageAddress.genKey("groundRodLevel", id))
        );
    }

    function rechargeEnergy(uint256 tokenId, bytes32 sid) public {
        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);

        (uint256 agentTokenId, , , , ) = getAgent(sid);

        uint256 id = storageAddress.getBytes32Uint(sid);

        require(IERC721(_agentPOPNFTAddress).ownerOf(agentTokenId) == msg.sender, "not owner");

        uint256 groundRodLevel = _groundRodLevels[tokenId];

        require(groundRodLevel > 0, "not found");

        IERC1155(_groundRodAddress).burn(msg.sender, tokenId, 1);

        storageAddress.setUint(storageAddress.genKey("groundRodLevel", id), groundRodLevel);

        emit eveRechargeEnergy(sid, groundRodLevel);
    }

    function generateUniqueHash(uint256 nextId) private view returns (bytes32) {
        return keccak256(abi.encodePacked(block.timestamp, block.difficulty, nextId));
    }
}
