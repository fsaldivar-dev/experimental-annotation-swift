# ``AnnotationSwift``

Anotaciones al estilo de Java para Swift: decoradores que se crean en un archivo y se apilan
sobre funciones y propiedades.

## Overview

Un decorador es un tipo que conforma ``Decorator`` (o ``HookDecorator``) para funciones, o
``PropertyDecorator`` para propiedades, más una línea que lo registra como anotación:

```swift
struct Logged: HookDecorator {
    func willCall(_ call: Call) { print("→ \(call)") }
}

@attached(peer) macro Logged() = #externalMacro(module: "AnnotationMacros", type: "MarkerMacro")
```

Se aplica apilado sobre los miembros de un tipo ``Decorable()``:

```swift
@Decorable
struct Service {
    @Logged
    @Retry(3)
    func fetch() async throws -> Data { … }
}
```

El primer marcador es el más externo: `Logged` envuelve a `Retry`, que envuelve al cuerpo.

## Topics

### Activar anotaciones

- ``Decorable()``

### Decorar funciones

- ``Decorator``
- ``HookDecorator``
- ``ThrowingDecorator``
- ``GuardDecorator``
- ``Call``

### Decorar propiedades

- ``PropertyDecorator``
- ``Property``
