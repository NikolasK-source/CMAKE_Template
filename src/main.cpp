/*
 * Copyright (C) 2020-2022 Nikolas Koesling <nikolas@koesling.info>.
 * This program is free software. You can redistribute it and/or modify it under the terms of the MIT License.
 */

#include "generated/version_info.hpp"

#include <iostream>

#ifdef _OPENMP
#    include <omp.h>
#endif

int main() {
    // TODO implement
    std::cout << version_info::NAME << ' ' << version_info::VERSION_STR << ' ' << "Hello CMake!!!\n";
    std::cout << "git commit: " << version_info::GIT_HASH << '\n';

#ifdef _OPENMP
#    pragma omp parallel default(none)
    { printf("Hello from thread: %d\n", omp_get_thread_num()); }
#endif
}
