## Unity Universal ShaderGraph Extensions
This plugin simply adds a Simple Lit material (SubTarget) to the Universal target for Shader Graph for URP.
If Unity ever implements the Simple Lit master node themselves, it should be an in-place replacement for this. To the point where you'll likely even get code conflicts.

## Dependencies
* This was coded to work for URP 13.1.7, but should work for any v13+. It might work for v12, but I've not tested it.
* This was coded to work for Unity 2022.1, and should work for any 2022+ version. It might work for 2021.2 & 2021.3, but I've not tested it.
* The changes to make it work for 2021.2+ & v12+ should be fairly minimal, if anyone wants to make that change and open a pull request.

## How to install
* Go to Package Manager in Unity
* Press the + in the top left
* Choose ADD PACKAGE FROM GIT URL
* Enter https://github.com/Zallist/unity-universal-shadergraph-extensions.git

## How to use
Once it's been installed, it should simply be a matter of just making a Shader Graph (there's an option in the Asset Creation menu for SIMPLE LIT SHADERGRAPH, near LIT SHADERGRAPH) and choosing the Material "Simple Lit". Basically the same way you'd make a Lit or Unlit shadergraph, instead just choose Simple Lit.

## Known issues
* VFX modifications have not been made, but should just be a missing GUI that needs to be created
* Deferred rendering path is not supported, since I didn't need it. Adding it should be a simple matter of creating the relevant .hlsl file for the GBuffers and then hooking the UniversalSimpleLitSubTarget to use it