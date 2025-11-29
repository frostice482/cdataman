# Amulet
A [Talisman](https://github.com/SpectralPack/Talisman) fork aiming to support high-scoring runs while keeping compat with other mods.
Specifically, it negates the `attempt to compare number with table`, and replacing OmegaNum objects with cdata variant.

The OmegaNum used is a port of [OmegaNum.js](https://github.com/Naruyoko/OmegaNum.js/blob/master/OmegaNum.js) by [Mathguy23](https://github.com/Mathguy23).

Amulet also contains _some_ changes that may not present in Talisman.

## Installation
Amulet requires [Lovely](https://github.com/ethangreen-dev/lovely-injector) to be installed in order to be loaded by Balatro.

## Limitations
- The largest ante before the new limit is approximately 1e300 due to BigNumber antes not being supported
