# identifiability-pk-pd-case
Example for identifiability for blog post

This repository contains an example of identifiability for a pharmacokinetic-pharmacodynamic (PK-PD) model, as discussed in [the blog post](https://metelkin.me).

## Model download

The model was taken from DigiPopRecepies

```sh
git clone --filter=blob:none --no-checkout https://github.com/hetalang/DigiPopRecipes.git tmp_repo
cd tmp_repo
git sparse-checkout init --cone
git sparse-checkout set models/01-multicompartment-pkpd
git checkout main

cd ..
mkdir -p model
cp -r tmp_repo/models/01-multicompartment-pkpd/* model/
rm -rf tmp_repo
```
