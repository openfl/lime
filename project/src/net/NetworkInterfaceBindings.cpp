#if defined (HX_WINDOWS) && !defined (HX_WINRT)
#define LIME_NETWORK_INTERFACES_WINDOWS
#include <winsock2.h>
#include <ws2tcpip.h>
#include <iphlpapi.h>
#elif !defined (EMSCRIPTEN) && !defined (HX_WINRT)
#define LIME_NETWORK_INTERFACES_POSIX
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <net/if.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <ifaddrs.h>
#include <unistd.h>
#if defined (__APPLE__)
#include <net/if_dl.h>
#else
#include <netpacket/packet.h>
#endif
#if defined (__ANDROID__)
#include <dlfcn.h>
#endif
#endif

#include <system/CFFI.h>
#include <system/System.h>
#include <stdio.h>
#include <string.h>
#include <string>
#include <vector>


namespace lime {


	// One interface's addresses, before they are written out
	struct NetworkAddress {

		std::string address;
		std::string broadcast;
		std::string version;
		int prefixLength;

	};


	struct NetworkInterfaceRecord {

		std::string name;
		std::string displayName;
		std::string hardwareAddress;
		bool active;
		int mtu;
		std::vector<NetworkAddress> addresses;

	};


	// Only where the system's socket headers are included: not on WebAssembly or WinRT, which list no
	// interfaces
	#if defined (LIME_NETWORK_INTERFACES_WINDOWS) || defined (LIME_NETWORK_INTERFACES_POSIX)
	static std::string FormatHardwareAddress (const unsigned char* data, int length) {

		std::string result;
		char part[4];

		for (int i = 0; i < length; i++) {

			snprintf (part, sizeof (part), i == 0 ? "%02X" : "-%02X", data[i]);
			result += part;

		}

		return result;

	}


	static std::string FormatIPv4Broadcast (const struct in_addr* address, int prefixLength) {

		if (prefixLength <= 0 || prefixLength >= 32) return "";

		unsigned long host = ntohl (address->s_addr);
		unsigned long mask = 0xFFFFFFFFul << (32 - prefixLength);
		struct in_addr broadcast;
		broadcast.s_addr = htonl ((host | ~mask) & 0xFFFFFFFFul);

		char text[INET_ADDRSTRLEN];
		if (!inet_ntop (AF_INET, &broadcast, text, sizeof (text))) return "";
		return text;

	}


	static bool FormatAddress (const struct sockaddr* address, NetworkAddress* result) {

		char text[INET6_ADDRSTRLEN];

		if (address->sa_family == AF_INET) {

			const struct sockaddr_in* ipv4 = (const struct sockaddr_in*)address;
			if (!inet_ntop (AF_INET, (void*)&ipv4->sin_addr, text, sizeof (text))) return false;
			result->version = "IPv4";

		} else if (address->sa_family == AF_INET6) {

			const struct sockaddr_in6* ipv6 = (const struct sockaddr_in6*)address;
			if (!inet_ntop (AF_INET6, (void*)&ipv6->sin6_addr, text, sizeof (text))) return false;
			result->version = "IPv6";

		} else {

			return false;

		}

		result->address = text;
		return true;

	}
	#endif


	#ifdef LIME_NETWORK_INTERFACES_WINDOWS
	static std::string WideToUTF8 (const wchar_t* text) {

		if (!text || !text[0]) return "";

		int length = WideCharToMultiByte (CP_UTF8, 0, text, -1, NULL, 0, NULL, NULL);
		if (length <= 1) return "";

		std::string result (length - 1, '\0');
		WideCharToMultiByte (CP_UTF8, 0, text, -1, &result[0], length, NULL, NULL);
		return result;

	}
	#endif


	static bool ListNetworkInterfaces (std::vector<NetworkInterfaceRecord>* interfaces) {

		#if defined (LIME_NETWORK_INTERFACES_WINDOWS)

		ULONG flags = GAA_FLAG_SKIP_ANYCAST | GAA_FLAG_SKIP_MULTICAST | GAA_FLAG_SKIP_DNS_SERVER;
		ULONG size = 16 * 1024;
		std::vector<unsigned char> buffer;
		ULONG status = ERROR_BUFFER_OVERFLOW;

		// The list can grow between the two calls, so ask again until it fits
		for (int attempt = 0; attempt < 4 && status == ERROR_BUFFER_OVERFLOW; attempt++) {

			buffer.resize (size);
			status = GetAdaptersAddresses (AF_UNSPEC, flags, NULL, (PIP_ADAPTER_ADDRESSES)&buffer[0], &size);

		}

		if (status == ERROR_NO_DATA) return true;
		if (status != NO_ERROR) return false;

		for (PIP_ADAPTER_ADDRESSES adapter = (PIP_ADAPTER_ADDRESSES)&buffer[0]; adapter; adapter = adapter->Next) {

			NetworkInterfaceRecord record;
			record.name = adapter->AdapterName ? adapter->AdapterName : "";
			record.displayName = WideToUTF8 (adapter->FriendlyName);
			if (record.displayName.empty ()) record.displayName = record.name;
			record.hardwareAddress = FormatHardwareAddress (adapter->PhysicalAddress, (int)adapter->PhysicalAddressLength);
			record.active = adapter->OperStatus == IfOperStatusUp;
			record.mtu = adapter->Mtu == 0xFFFFFFFF ? -1 : (int)adapter->Mtu;

			for (PIP_ADAPTER_UNICAST_ADDRESS unicast = adapter->FirstUnicastAddress; unicast; unicast = unicast->Next) {

				NetworkAddress address;
				if (!FormatAddress (unicast->Address.lpSockaddr, &address)) continue;
				address.prefixLength = unicast->OnLinkPrefixLength;

				if (unicast->Address.lpSockaddr->sa_family == AF_INET) {

					address.broadcast = FormatIPv4Broadcast (&((struct sockaddr_in*)unicast->Address.lpSockaddr)->sin_addr, address.prefixLength);

				}

				record.addresses.push_back (address);

			}

			interfaces->push_back (record);

		}

		return true;

		#elif defined (LIME_NETWORK_INTERFACES_POSIX)

		#if defined (__ANDROID__)
		// getifaddrs is in Android 7.0 (API 24) and later, and Lime builds for API 21
		typedef int (*GetIfAddrsFunction) (struct ifaddrs**);
		typedef void (*FreeIfAddrsFunction) (struct ifaddrs*);
		static GetIfAddrsFunction getInterfaceAddresses = (GetIfAddrsFunction)dlsym (RTLD_DEFAULT, "getifaddrs");
		static FreeIfAddrsFunction freeInterfaceAddresses = (FreeIfAddrsFunction)dlsym (RTLD_DEFAULT, "freeifaddrs");
		if (!getInterfaceAddresses || !freeInterfaceAddresses) return false;
		#else
		int (*getInterfaceAddresses) (struct ifaddrs**) = getifaddrs;
		void (*freeInterfaceAddresses) (struct ifaddrs*) = freeifaddrs;
		#endif

		struct ifaddrs* list = NULL;
		if (getInterfaceAddresses (&list) != 0) return false;

		int sock = socket (AF_INET, SOCK_DGRAM, 0);

		for (struct ifaddrs* entry = list; entry; entry = entry->ifa_next) {

			if (!entry->ifa_name) continue;

			// getifaddrs lists each address on its own, so group them by interface
			NetworkInterfaceRecord* record = NULL;

			for (size_t i = 0; i < interfaces->size (); i++) {

				if ((*interfaces)[i].name == entry->ifa_name) {

					record = &(*interfaces)[i];
					break;

				}

			}

			if (!record) {

				NetworkInterfaceRecord created;
				created.name = entry->ifa_name;
				created.displayName = entry->ifa_name;
				created.active = (entry->ifa_flags & IFF_UP) && (entry->ifa_flags & IFF_RUNNING);
				created.mtu = -1;

				if (sock >= 0) {

					struct ifreq request;
					memset (&request, 0, sizeof (request));
					strncpy (request.ifr_name, entry->ifa_name, IFNAMSIZ - 1);
					if (ioctl (sock, SIOCGIFMTU, &request) == 0) created.mtu = request.ifr_mtu;

				}

				interfaces->push_back (created);
				record = &interfaces->back ();

			}

			if (!entry->ifa_addr) continue;

			#if defined (__APPLE__)
			if (entry->ifa_addr->sa_family == AF_LINK) {

				const struct sockaddr_dl* link = (const struct sockaddr_dl*)entry->ifa_addr;
				std::string hardwareAddress = FormatHardwareAddress ((const unsigned char*)LLADDR (link), link->sdl_alen);

				// iOS gives apps this address in place of the real one
				if (hardwareAddress != "02-00-00-00-00-00") record->hardwareAddress = hardwareAddress;
				continue;

			}
			#else
			if (entry->ifa_addr->sa_family == AF_PACKET) {

				const struct sockaddr_ll* link = (const struct sockaddr_ll*)entry->ifa_addr;
				bool zero = true;
				for (int i = 0; i < link->sll_halen; i++) if (link->sll_addr[i] != 0) zero = false;
				if (link->sll_halen > 0 && !zero) record->hardwareAddress = FormatHardwareAddress (link->sll_addr, link->sll_halen);
				continue;

			}
			#endif

			NetworkAddress address;
			if (!FormatAddress (entry->ifa_addr, &address)) continue;
			address.prefixLength = 0;

			if (entry->ifa_netmask) {

				const unsigned char* mask = NULL;
				int length = 0;

				if (entry->ifa_addr->sa_family == AF_INET) {

					mask = (const unsigned char*)&((const struct sockaddr_in*)entry->ifa_netmask)->sin_addr;
					length = 4;

				} else {

					mask = (const unsigned char*)&((const struct sockaddr_in6*)entry->ifa_netmask)->sin6_addr;
					length = 16;

				}

				for (int i = 0; i < length; i++) {

					for (unsigned char bit = 0x80; bit; bit >>= 1) {

						if (mask[i] & bit) address.prefixLength++;

					}

				}

			}

			if (entry->ifa_addr->sa_family == AF_INET && (entry->ifa_flags & IFF_BROADCAST) && entry->ifa_broadaddr) {

				char text[INET_ADDRSTRLEN];
				if (inet_ntop (AF_INET, (void*)&((const struct sockaddr_in*)entry->ifa_broadaddr)->sin_addr, text, sizeof (text))) address.broadcast = text;

			}

			record->addresses.push_back (address);

		}

		if (sock >= 0) close (sock);
		freeInterfaceAddresses (list);
		return true;

		#else

		return false;

		#endif

	}


	// One record per interface, its fields split by 0x1F, and the records by 0x1E,
	// so every target reads the list the same way
	static bool GetNetworkInterfaces (std::string* result) {

		std::vector<NetworkInterfaceRecord> interfaces;
		if (!ListNetworkInterfaces (&interfaces)) return false;

		char number[16];

		for (size_t i = 0; i < interfaces.size (); i++) {

			const NetworkInterfaceRecord& record = interfaces[i];
			if (i > 0) *result += '\x1E';

			*result += record.name;
			*result += '\x1F';
			*result += record.displayName;
			*result += '\x1F';
			*result += record.hardwareAddress;
			*result += '\x1F';
			*result += record.active ? "1" : "0";
			*result += '\x1F';
			snprintf (number, sizeof (number), "%d", record.mtu);
			*result += number;

			for (size_t j = 0; j < record.addresses.size (); j++) {

				const NetworkAddress& address = record.addresses[j];
				*result += '\x1F';
				*result += address.address;
				*result += '\x1F';
				*result += address.broadcast;
				*result += '\x1F';
				*result += address.version;
				*result += '\x1F';
				snprintf (number, sizeof (number), "%d", address.prefixLength);
				*result += number;

			}

		}

		return true;

	}


	value lime_network_interface_get_interfaces () {

		std::string interfaces;

		// Asking the adapters can take a moment, so let the GC run meanwhile
		System::GCEnterBlocking ();
		bool listed = GetNetworkInterfaces (&interfaces);
		System::GCExitBlocking ();

		if (!listed) return alloc_null ();
		return alloc_string_len (interfaces.c_str (), (int)interfaces.size ());

	}


	HL_PRIM vbyte* HL_NAME(hl_network_interface_get_interfaces) () {

		std::string interfaces;

		hl_blocking (true);
		bool listed = GetNetworkInterfaces (&interfaces);
		hl_blocking (false);

		if (!listed) return NULL;

		vbyte* result = hl_alloc_bytes ((int)interfaces.size () + 1);
		memcpy (result, interfaces.c_str (), interfaces.size () + 1);
		return result;

	}


	bool lime_network_interface_is_supported () {

		#if defined (LIME_NETWORK_INTERFACES_WINDOWS)
		return true;
		#elif defined (LIME_NETWORK_INTERFACES_POSIX) && defined (__ANDROID__)
		return dlsym (RTLD_DEFAULT, "getifaddrs") != NULL;
		#elif defined (LIME_NETWORK_INTERFACES_POSIX)
		return true;
		#else
		return false;
		#endif

	}


	HL_PRIM bool HL_NAME(hl_network_interface_is_supported) () {

		return lime_network_interface_is_supported ();

	}


	DEFINE_PRIME0 (lime_network_interface_get_interfaces);
	DEFINE_PRIME0 (lime_network_interface_is_supported);

	DEFINE_HL_PRIM (_BYTES, hl_network_interface_get_interfaces, _NO_ARG);
	DEFINE_HL_PRIM (_BOOL, hl_network_interface_is_supported, _NO_ARG);


}


extern "C" int lime_network_interface_register_prims () {

	return 0;

}
