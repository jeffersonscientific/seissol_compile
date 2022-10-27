# seissol_compile
Compile (and similar) script for SeisSol
#
To date, these scripts can be used to install SeisSol on Stanford Research Computing's Sherlock HPC. The `compile_seissol_spack.sh` script primarily uses a `spack` built environment, and so can be adapted to another HPC relatively easily.

The `compile_seissol_sherlock.sh` script might be refrenced as a template -- the idea being to use pre-built SW modules to build SeisSol, but it ultimately crashes and burns prety spetacularly. One issue is that the various components may have differend dependencies. Namely, some packages are built from a `gcc/10.1.0` toolchain and another from `gcc/12.1.0`.

Files:
  - `build_spack_env.sh`: a generic batchable bash script to build a spack environment.
  - `ss_env.yaml`: Should be the einvironment file we use to define the `seissol` spack environment. Note that the environment includes some external package definitions and Sherlock's built in `gcc` compilers, including the primary `gcc@12.1.0`. These will need to be modified to deploy on a different HPC. Compilers can be built natively in Spack, then automagically discovered and added, but ultimately it will still likely be neessary to modify their definition in the environment file.
  - `compile_seissol_spack.sh`: Working (on Sherlock HPC) compile script. will build all the non-Spack components
  - `compile_seissol_cees_sherlock`: An older compile script that attempts to use Sherlock's standard SW to compile. It ultimately crashes and burns, but might be referenced as a template.
  - `install_ss_spack.sh`: An early template to build the Spack environment from scratch, including building, and `find`ing compilers in Spack.
 
