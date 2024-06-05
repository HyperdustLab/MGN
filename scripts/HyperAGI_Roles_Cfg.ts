/** @format */

import { ethers, run, upgrades } from 'hardhat'

require('dotenv').config()

async function main() {
  const contract = await ethers.getContractFactory('HyperAGI_Roles_Cfg')
  const instance = await upgrades.deployProxy(contract, [process.env.ADMIN_Wallet_Address])

  await instance.waitForDeployment()

  console.info('contractFactory address:', instance.target)

  // 获取实现合约的地址

  const instance_Impl = await upgrades.erc1967.getImplementationAddress(instance.target)

  // 显示实现合约的地址
  console.info('HyperAGI_Security_Deposit Implementation Address:', instance_Impl)
}

// We recommend this pattern to be able to use async/await everywhere q
// and properly handle errors.
main().catch(error => {
  console.error(error)
  process.exitCode = 1
})
