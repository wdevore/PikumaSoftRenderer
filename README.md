# PikumaSoftRenderer
An adaptation of Pikuma's 3D software renderer course (no textures)

# Blender export to Wavefront

![Export](blender_export_to_wavefront.png)

# Event filter error:
Long shot, but is there an additional error or anything on Uint8 or something causing that class to be unresolved? If Uint8 isn't available for some reason (e.g. because you have a show modifier on an ffi import or another import exposing a symbol with the same name), then Pointer<Uint8> gets analyzed as Pointer<Invalid> which gets instantiated to bounds, Pointer<NativeType>. That then causes the very confusing analyzer failure. 