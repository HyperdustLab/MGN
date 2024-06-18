pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/Strings.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import {StrUtil} from "../utils/StrUtil.sol";

import "./../HyperAGI_Storage.sol";

import "./HyperAGI_Miner_NFT_Pledge.sol";

contract HyperAGI_AI_Node_Mgr is OwnableUpgradeable {
    using Strings for *;
    using StrUtil for *;

    address public _rolesCfgAddress;
    address public _storageAddress;
    address public _minerNFTPledgeAddress;

    event eveSave(uint256 id);

    event eveDelete(uint256 id);

    function initialize(address onlyOwner) public initializer {
        __Ownable_init(onlyOwner);
    }

    function setRolesCfgAddress(address rolesCfgAddress) public onlyOwner {
        _rolesCfgAddress = rolesCfgAddress;
    }

    function setStorageAddress(address storageAddress) public onlyOwner {
        _storageAddress = storageAddress;
    }

    function setMinerNFTPledgeAddress(address minerNFTPledgeAddress) public onlyOwner {
        _minerNFTPledgeAddress = minerNFTPledgeAddress;
    }

    function setContractAddress(address[] memory contractaddressArray) public onlyOwner {
        _rolesCfgAddress = contractaddressArray[0];
        _storageAddress = contractaddressArray[1];
        _minerNFTPledgeAddress = contractaddressArray[2];
    }

    function addNode(string[] memory ipList, string[] memory portList, string[] memory serviceNameList, address[] memory accountList, uint256[] memory feeList) public {
        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);
        require(HyperAGI_Roles_Cfg(_rolesCfgAddress).hasAdminRole(msg.sender), "not admin role");

        for (uint256 i = 0; i < ipList.length; i++) {
            uint256 id = storageAddress.getNextId();

            string memory ipKey = string(abi.encodePacked(ip, "_", port));

            if (storageAddress.getBool(ipKey)) {
                continue;
            }

            storageAddress.setBool(ipKey, true);

            storageAddress.setString(storageAddress.genKey("ip", id), ipList[i]);
            storageAddress.setString(storageAddress.genKey("port", id), portList[i]);
            storageAddress.setString(storageAddress.genKey("serviceName", id), serviceNameList[i]);
            storageAddress.setAddress(storageAddress.genKey("account", id), accountList[i]);
            storageAddress.setBytes1(storageAddress.genKey("status", id), 0x00);
            storageAddress.setUint(storageAddress.genKey("fee", id), feeList[i]);

            emit eveSave(id);
        }
    }

    function add(uint256 id, uint256 nodeTypeId, address incomeAddress, string memory ip, uint256[] memory hardwareInfos) private {
        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);

        uint256 count = storageAddress.getUint("count");

        storageAddress.setBool(ip, true);

        storageAddress.setUint("count", count + 1);

        storageAddress.setUint(storageAddress.genKey("nodeTypeId", id), nodeTypeId);

        storageAddress.setUint(storageAddress.genKey("cpuNum", id), hardwareInfos[0]);

        storageAddress.setUint(storageAddress.genKey("memoryNum", id), hardwareInfos[1]);

        storageAddress.setUint(storageAddress.genKey("diskNum", id), hardwareInfos[2]);

        storageAddress.setUint(storageAddress.genKey("cudaNum", id), hardwareInfos[3]);

        storageAddress.setUint(storageAddress.genKey("videoMemory", id), hardwareInfos[4]);

        storageAddress.setAddress(storageAddress.genKey("incomeAddress", id), incomeAddress);

        storageAddress.setString(storageAddress.genKey("ip", id), ip);

        storageAddress.setUintArray("idList", id);

        emit eveSave(id);
    }

    function getNode(uint256 id) public view returns (address, string memory, uint256[] memory, bool) {
        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);
        string memory ip = storageAddress.getString(storageAddress.genKey("ip", id));

        require(bytes(ip).length > 0, "not found");

        address incomeAddress = storageAddress.getAddress(storageAddress.genKey("incomeAddress", id));

        uint256[] memory uint256Array = new uint256[](7);

        uint256Array[0] = id;
        uint256Array[1] = storageAddress.getUint(storageAddress.genKey("nodeTypeId", id));
        uint256Array[2] = storageAddress.getUint(storageAddress.genKey("cpuNum", id));
        uint256Array[3] = storageAddress.getUint(storageAddress.genKey("memoryNum", id));
        uint256Array[4] = storageAddress.getUint(storageAddress.genKey("diskNum", id));
        uint256Array[5] = storageAddress.getUint(storageAddress.genKey("cudaNum", id));
        uint256Array[6] = storageAddress.getUint(storageAddress.genKey("videoMemory", id));

        bool isOffline = storageAddress.getBool(storageAddress.genKey("isOffine", id));

        return (incomeAddress, ip, uint256Array, isOffline);
    }

    function getNodeObj(uint256 id) public view returns (Node memory) {
        (address incomeAddress, string memory ip, uint256[] memory uint256Array, bool isOffline) = getNode(id);

        Node memory node = Node({incomeAddress: incomeAddress, ip: ip, uint256Array: uint256Array, isOffline: isOffline});

        return node;
    }

    function deleteNode(uint256 id) public {
        require(HyperAGI_Roles_Cfg(_rolesCfgAddress).hasAdminRole(msg.sender), "not admin role");

        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);

        string memory ip = storageAddress.getString(storageAddress.genKey("ip", id));

        require(bytes(ip).length > 0, "not found");

        storageAddress.setString(storageAddress.genKey("ip", id), "");

        uint256 count = storageAddress.getUint("count");

        storageAddress.setUint("count", count - 1);

        uint256[] memory idList = storageAddress.getUintArray("idList");

        for (uint i = 0; i < idList.length; i++) {
            if (idList[i] == id) {
                storageAddress.removeStringArray("idList", i);
                break;
            }
        }

        emit eveDelete(id);
    }

    function getStatisticalIndex() public view returns (uint256, uint256, uint256) {
        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);
        uint256 count = storageAddress.getUint("count");
        uint256 totalNum = storageAddress.getUint("totalNum");
        uint256 activeNum = storageAddress.getUint("activeNum");

        return (count, totalNum, activeNum);
    }

    function setStatisticalIndex(uint256 totalNum, uint256 activeNum) public {
        require(HyperAGI_Roles_Cfg(_rolesCfgAddress).hasAdminRole(msg.sender), "not admin role");

        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);

        storageAddress.setUint("totalNum", totalNum);
        storageAddress.setUint("activeNum", activeNum);
    }

    function getIdByIndex(uint256 index) public view returns (uint256) {
        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);

        uint256[] memory ids = storageAddress.getUintArray("idList");

        if (index + 1 > ids.length) {
            return 0;
        }

        return ids[index];
    }

    function setIdList(uint256[] memory idList) public onlyOwner {
        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);

        storageAddress.setUintArray("idList", idList);
    }

    function updateStatus(uint256 nodeId, bool isOffline) public {
        require(HyperAGI_Roles_Cfg(_rolesCfgAddress).hasAdminRole(msg.sender), "not admin role");
        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);

        HyperAGI_Miner_NFT_Pledge minerNFTPledgeAddress = HyperAGI_Miner_NFT_Pledge(_minerNFTPledgeAddress);

        address incomeAddress = storageAddress.getAddress(storageAddress.genKey("incomeAddress", nodeId));

        uint256 pledgeNum = minerNFTPledgeAddress.getAccountPledgeNum(incomeAddress);

        string memory accountKey = incomeAddress.toHexString();

        storageAddress.setBool(storageAddress.genKey("isOffline", nodeId), isOffline);

        uint256 nodeNum = storageAddress.getUint(accountKey);

        if (isOffline) {
            storageAddress.setUint(accountKey, nodeNum - 1);
        } else {
            require(nodeNum + 1 >= pledgeNum, "The amount of pledged NFT is insufficient, please pledge the NFT first");
            storageAddress.setUint(accountKey, nodeNum + 1);
        }

        emit eveSave(nodeId);
    }

    function getAccountNodeNum(address account) public view returns (uint256) {
        HyperAGI_Storage storageAddress = HyperAGI_Storage(_storageAddress);
        string memory accountKey = account.toHexString();
        return storageAddress.getUint(accountKey);
    }
}