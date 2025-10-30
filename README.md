# cdataman
A [Talisman](https://github.com/SpectralPack/Talisman) fork aiming to support high-scoring runs while keeping compat with other mods.
Specifically, it negates the `attempt to compare number with table`, and replacing OmegaNum objects with cdata variant.

The OmegaNum used is a port of [OmegaNum.js](https://github.com/Naruyoko/OmegaNum.js/blob/master/OmegaNum.js) by [Mathguy23](https://github.com/Mathguy23).

Cdataman also contains _some_ changes that may not present in Talisman.

## Installation
Cdataman requires [Lovely](https://github.com/ethangreen-dev/lovely-injector) to be installed in order to be loaded by Balatro.

## Incompatibles

### Cryptid (0.5.13)

- Value manipulation that reaches e300 won't apply
- Enabling type compat will cause crash
- No true solution for now

### Overflow (1.0.4)

- Overrides `to_big` completely if SMODS or Talisman is not present
- Solution: install a placeholder Talisman mod

## Limitations
- High scores will not be saved to your profile (this is to prevent your profile save from being incompatible with an unmodified instance of Balatro)
- Savefiles created/opened with Talisman aren't backwards-compatible with unmodified versions of Balatro.
- The largest ante before the new limit is approximately 1e300 due to BigNumber antes not being supported
