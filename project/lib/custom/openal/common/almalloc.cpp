// Replaces OpenAL Soft's common/almalloc.cpp, which gives macOS targets before 10.13 the aligned
// operator new their system library lacks, with posix_memalign. posix_memalign only takes an
// alignment that is a multiple of sizeof(void*), but OpenAL Soft's al::allocator asks for the
// alignment of the type it allocates, which can be smaller. Effect and filter batches failed to
// allocate that way, so alGenEffects and alGenFilters reported AL_OUT_OF_MEMORY on macOS. The
// alignment is raised to at least sizeof(void*) here, which still meets the one asked for.
#include "almalloc.h"

#if defined(__APPLE__)
#include <AvailabilityMacros.h>

#if defined(MAC_OS_X_VERSION_MIN_REQUIRED) && MAC_OS_X_VERSION_MIN_REQUIRED < 101300

#include <stdlib.h>

namespace {

auto lime_aligned_alloc(std::size_t const len, std::align_val_t const align) noexcept -> void*
{
    auto alignment = static_cast<std::size_t>(align);
    if(alignment < sizeof(void*))
        alignment = sizeof(void*);

    void *mem{};
    if(posix_memalign(&mem, alignment, len ? len : 1))
        return nullptr;
    return mem;
}

} // namespace

auto operator new(std::size_t const len, std::align_val_t const align, std::nothrow_t const&)
    noexcept -> gsl::owner<void*>
{ return lime_aligned_alloc(len, align); }
auto operator new[](std::size_t const len, std::align_val_t const align, std::nothrow_t const &tag)
    noexcept -> gsl::owner<void*>
{ return operator new(len, align, tag); }

auto operator new(std::size_t const len, std::align_val_t const align) -> gsl::owner<void*>
{
    if(auto *mem = lime_aligned_alloc(len, align))
        return mem;
    throw std::bad_alloc();
}
auto operator new[](std::size_t const len, std::align_val_t const align) -> gsl::owner<void*>
{ return operator new(len, align); }

auto operator delete(gsl::owner<void*> const ptr, std::align_val_t) noexcept -> void
{ free(ptr); }
auto operator delete[](gsl::owner<void*> const ptr, std::align_val_t) noexcept -> void
{ free(ptr); }

auto operator delete(gsl::owner<void*> const ptr, std::size_t, std::align_val_t) noexcept -> void
{ free(ptr); }
auto operator delete[](gsl::owner<void*> const ptr, std::size_t, std::align_val_t) noexcept -> void
{ free(ptr); }

auto operator delete(gsl::owner<void*> const ptr, std::align_val_t, std::nothrow_t const&) noexcept
    -> void
{ free(ptr); }
auto operator delete[](gsl::owner<void*> const ptr, std::align_val_t, std::nothrow_t const&)
    noexcept -> void
{ free(ptr); }

#endif
#endif
