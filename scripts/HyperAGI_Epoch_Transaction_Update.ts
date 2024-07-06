/** @format */

import { ethers, run, upgrades } from 'hardhat'

async function main() {
  const _HyperAGI_Epoch_Transaction = await ethers.getContractFactory('HyperAGI_Epoch_Transaction')

  await upgrades.upgradeProxy('0x2Fde2e0306540B9b7B90BF6D858Ee3e387389F32', _HyperAGI_Epoch_Transaction)
}

// We recommend this pattern to be able to use async/await everywhere q
// and properly handle errors.
main().catch(error => {
  console.error(error)
  process.exitCode = 1
})