## Unity Universal ShaderGraph Extensions
This plugin simply adds a Simple Lit material (SubTarget) to the Universal target for Shader Graph for URP.
If Unity ever implements the Simple Lit master node themselves, it should be an in-place replacement for this. To the point where you'll likely even get code conflicts.

## Dependencies
* Works on Unity version 2021.2 or higher, with URP version 12 or higher

## How to install
* Go to Package Manager in Unity
* Press the + in the top left
* Choose ADD PACKAGE FROM GIT URL
* Enter https://github.com/Zallist/unity-universal-shadergraph-extensions.git

## How to use
Once it's been installed, it should simply be a matter of just making a Shader Graph (there's an option in the Asset Creation menu for SIMPLE LIT SHADERGRAPH, near LIT SHADERGRAPH) and choosing the Material "Simple Lit". Basically the same way you'd make a Lit or Unlit shadergraph, instead just choose Simple Lit.

### Example
![Shader Graph](https://i.imgur.com/r4LI0g5.png)