/** @format */

import { ethers, run, upgrades } from 'hardhat'

async function main() {
  const _HyperAGI_Storage = await ethers.getContractFactory('HyperAGI_Storage')
  const HyperAGI_Storage = await upgrades.deployProxy(_HyperAGI_Storage, [process.env.ADMIN_Wallet_Address])
  await HyperAGI_Storage.waitForDeployment()

  const contract = await ethers.getContractFactory('HyperAGI_Ecpoch_Transaction')
  const instance = await upgrades.deployProxy(contract, [process.env.ADMIN_Wallet_Address])
  await instance.waitForDeployment()

  console.info('HyperAGI_Storage:', HyperAGI_Storage.target)

  await (
    await instance.setContractAddress(['0x5745090BFB28C3399223215DfbBb4e729aeF8cFD', '0x829551330A37140764573d0B3236E9Db71b4B196', '0x859133fA725Cd252FD633E0Bc9ef7BbA270d6BE7', '0xb2342E1Bf4B4e0d340B97F5CdD8Fd9Cf24525D26', HyperAGI_Storage.target, '0x913279cA4E351E24a9b77Bcdd32dE0D546291D7a'])
  ).wait()

  await (await HyperAGI_Storage.setServiceAddress(instance.target)).wait()

  const HyperAGI_Roles_Cfg = await ethers.getContractAt('HyperAGI_Roles_Cfg', '0x5745090BFB28C3399223215DfbBb4e729aeF8cFD')
  await (await HyperAGI_Roles_Cfg.addAdmin(instance.target)).wait()

  console.info('contractFactory address:', instance.target)
}

// We recommend this pattern to be able to use async/await everywhere q
// and properly handle errors.
main().catch(error => {
  console.error(error)
  process.exitCode = 1
})
