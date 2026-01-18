# Schematic to Roblox

A Roblox plugin to convert Minecraft schematics to Roblox models.

Right now, the plugin must be built from source manually. When a release is made, I will probably attach an RBXM file of the plugin. Uploading to the marketplace is also intriguing.

Some parts of the plugin, such as [named-binary-tag](./src/modules/named_binary_tag.luau), would work well as pesde packages. I will consider it. Please create an issue if you would like this so that I will see the demand.

## Table of Contents

- [Building](#building)
- [Scripts](#scripts)
- [Credits](#credits)
- [License](#license)

## Building

Necessary tools:
- pesde: <https://docs.pesde.dev/installation/>
- Rojo: <https://rojo.space/docs/v7/getting-started/installation/>

Recommended tools:
- Rokit: <https://github.com/rojo-rbx/rokit?tab=readme-ov-file#installation>

If Rokit is installed, run `rokit install` to get Rojo.

If you want automatically generated textures for most Minecraft blocks, put a Minecraft texture pack at `./block_properties/textures`. With the default texture pack, not all blocks work:
- Some have multiple texture files, each with a slightly off name, such as `acacia_door_bottom.png` and `acacia_door_top.png`. Neither is exactly `acacia_door.png`, so the generation fails. Perhaps the algorithm could be hardcoded to ignore certain suffixes, such as `bottom` and `top`.
- Leaves are grayscale for some reason. The computed transparency is probably accurate, but the colour is way off.

To build the plugin, run:
- `pesde install`
- `pesde run generate_block_properties`
- `pesde run build`

This command will hang since it watches for file changes in order to rebuild with the latest changes.

Honestly, I am not 100% sure if this tutorial is complete. I also have Lune installed, but I am not sure if it is necessary to manually install or if pesde gets it. I am also not sure if updating the sourcemap is necessary.

## Scripts

These can be run using `pesde run [name]`.

- generate_block_properties: Generate Roblox properties from a Minecraft texture pack.
- roblox_sync_config_generator: Not sure. pesde automatically added it.
- sourcemap_generator: Not sure. pesde automatically added it.
- test: Run all tests.

## Credits

[DarkenedRing](<https://github.com/DarkenedRing/>) contributed a lot.

## License

MIT License. If you contribute, you agree for all of your contributions to be licensed under the MIT License.
