# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-10-21
Reescritura completa. Las anotaciones dejan de ser validadores y pasan a ser decoradores
que se crean en un archivo y se apilan sobre funciones y propiedades.

### Added
- `@Decorable`: procesador que activa los marcadores apilados en los miembros de un tipo o extensión.
- `MarkerMacro`: marcador genérico; cada anotación de usuario se registra con una línea.
- `Decorator` y `HookDecorator` para envolver funciones síncronas y `async`, con o sin `throws`,
  respetando el aislamiento del actor.
- `ThrowingDecorator` y `GuardDecorator` para decoradores que lanzan por su cuenta (guardianes, timeouts).
- `PropertyDecorator` para envolver la inicialización y asignación de propiedades almacenadas.
- `Call` y `Property` con los metadatos de la declaración decorada.
- Diagnósticos de compilación: marcador sin `@Decorable`, `let`, propiedades computadas,
  `static`/`lazy`, propiedades en extensiones, `throws` tipado.
- Paquetes de ejemplo `Examples/Demo` (consola) y `Examples/AdminApp` (SwiftUI, guardianes de navegación con roles).
- Tests con swift-testing (end-to-end) y XCTest (expansión de macros).

### Changed
- Swift 6 (`swift-tools-version: 6.0`, modo de lenguaje 6, concurrencia estricta).
- El tipo de la propiedad decorada ya no necesita ser opcional.

### Removed
- API 0.x: `ASGroup`, `ASAnnotation`, `ASAnnotationWrapped`, `ASAnnotationGroup`, `Email`,
  `LowCase`, `MinLength`, `MaxLength`.
- Soporte de CocoaPods y el proyecto `Example` de UIKit.

## [0.0.3] - 2022-07-31
### Added
- implement Cocoa pods suport.[#PR-2](https://github.com/JavierSaldivarRubio/experimental-annotation-swift/pull/2)
- Licence [#PR-1](https://github.com/JavierSaldivarRubio/experimental-annotation-swift/pull/1)

## [0.0.2] - 2021-08-02
### Refactor
- Refactor name library commit from [@fsaldivar-dev](https://github.com/JavierSaldivarRubio/experimental-annotation-swift/commit/7f09747d4df2c59be4d41da20599d1367b62abee)

## [0.0.1] - 2021-07-31
### Added
- Add workspace commit from [@fsaldivar-dev](https://github.com/JavierSaldivarRubio/experimental-annotation-swift/commit/c51707fe06fcadaaf39bfde72a267f361299f139)
