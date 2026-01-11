# Schematic to Roblox

A Roblox plugin to convert Minecraft schematics to Roblox models.

[DarkenedRing](<https://github.com/DarkenedRing/>) contributed a lot.

Right now, the plugin must be built from source manually. When a release is made, I will probably attach an RBXM file of the plugin. Uploading to the marketplace is also intriguing.

Some parts of the plugin, such as [named-binary-tag](./src/modules/named_binary_tag.luau), would work well as pesde packages. I will consider it. Please create an issue if you would like this so that I will see the demand.

## Scripts

These can be run using `pesde run [name]`.

- generate_block_properties: Generate Roblox properties from a Minecraft texture pack.
- roblox_sync_config_generator: Not sure. pesde automatically added it.
- sourcemap_generator: Not sure. pesde automatically added it.
- test: Run all tests.
