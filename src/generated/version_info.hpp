/*
 * Copyright (C) 2024 Nikolas Koesling <nikolas@koesling.info>.
 * This program is free software. You can redistribute it and/or modify it under the terms of the MIT License.
 */

#include <string>

/**
 * @brief struct that contains version information
 * @details contains only static members --> no instance can be created
 */
struct version_info {
    //* Mayor version number
    static constexpr int MAYOR = PROJECT_VERSION_MAJOR;

    //* Minor version number
    static constexpr int MINOR = PROJECT_VERSION_MINOR;

    //* Patchlevel
    static constexpr int PATCH = PROJECT_VERSION_PATCH;

    //* Complete version as string
    static const std::string VERSION_STR;

    //* cmake project name
    static const std::string NAME;

    //* compiler info
    static const std::string COMPILER;

    //* host system info
    static const std::string SYSTEM;

    /**
     * @brief git hash
     * @details
     *  Contains the complete git hash.
     *  If there are uncommitted changes in the repository,
     *      the suffix '-dirty' is appended
     */
    static const std::string GIT_HASH;

private:
    version_info() = default;
};
