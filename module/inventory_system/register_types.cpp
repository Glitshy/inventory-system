#include "register_types.h"
#include "core/object/object.h"
#include "core/extension/gdextension_interface.h"
#include "core/extension/gdextension_manager.h"
#include "./gdextension_static_library_loader.h"
#include "core/object/ref_counted.h"

extern "C" {
    GDExtensionBool inventory_system_init(
        GDExtensionInterfaceGetProcAddress p_get_proc_address,
        GDExtensionClassLibraryPtr p_library,
        GDExtensionInitialization *r_initialization
    );
}

void initialize_inventory_system_module(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SERVERS) {
		return;
	}

	Ref<GDExtensionStaticLibraryLoader> loader;
	loader.instantiate();
	loader->set_entry_funcptr((void *)&inventory_system_init);
	GDExtensionManager::get_singleton()->load_extension_with_loader("inventory_system", loader);
}

void uninitialize_inventory_system_module(ModuleInitializationLevel p_level) {
}
