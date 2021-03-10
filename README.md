# vsd-contract

Value Set Dollar (VSD) is a value-backed, self-stabilizing, and decentralized stablecoin with a basket of collateral backing and algorithmic incentive mechanism. It has 8 key features:
- Stability - VSD uses an algorithmic and partially collateral approach to maintaining price stability around a 1 USDC/DAI target. This approach relies on a tuned incentive mechanisms, such as coupon premium and coupon extension.
- Composability - Value Set Dollar is an ERC-20 token standards, this means that it can be used just like DAI, seamlessly across the DeFi infrastructure and reduces the likelihood of unforeseen bugs in integrated protocols.
- Merged DAO + LP - We’ve merged DAO and LP from the original design of ESD, since participants in DAO have almost zero risk and crazy upside, they would most likely dump on the market during contraction. Governance is done through Bonded LPs, who have the most skin in the game, as they are providing on-chain liquidity.
- Multiple Pools - We’ve added multiple LP pools to maximize composability and accessibility. From the start there will be pools on both Uniswap and Sushiswap with different stablecoins, such as USDT, USDC, and DAI.
- Partial Collateral - VSD is partially backed by a basket of collaterals (USDC/DAI/USDT) and partially stabilized algorithmically.
- Improved Coupon System: We’ve improved the coupon system by reducing the duration to 10 days, and added a new feature where users can extend their duration by burning a percentage of their VSD. This helps reduce VSD supply and encourage buy pressure during contraction.
- Expansion Fee: The system sells a percentage of expansion during every epoch, these stablecoins are then added into the collateral reserve which is redeemable during contraction.
- Decentralization - Since day one Value Set Dollar has had completely decentralized on-chain governance.

# Contracts
- Main: 0x05bab9017705d32a8a0bb2ec06a78fa0fa20f1a4
- Oracle: 0x7c9ab6d405e04537731efdf1ed7da613660f9880
- Dollar: 0x35de3eccaccb02e627062b5d63aa941b137288fe
- VSD-USDC Uniswap pair: 0x88c3Eb319718686675f8A6Cfdb8a6d2Cf56fbAa9
- VSD-DAI Uniswap pair: 0xcff350Bbe5f9834b8BD8E45909bc03B571a46693
- VSD-USDT Uniswap pair: 0x84372e2dD7C4BE8D9963Aac727f25ee66C51D623
- VSD-WETH Uniswap pair: 0xe8A8f27EcEf44Ccc928a4e98226440fDA0e19Fe9
