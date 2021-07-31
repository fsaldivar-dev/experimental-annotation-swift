# esperimental-annotation-swift

Librería que se usa para anidar anotaciones

# Teoría
En java se conoce ya desde hace mucho tiempo las funciones denominadas anotaciones las cuales son muy comunes en sprint, o al usar la serialización con gson en android, en iOS no existia sino hace pocos años el uso de [**property wrappers**](https://docs.swift.org/swift-book/LanguageGuide/Properties.html)

si bien es muy similar a las anotaciones de java, aun son muy simples y su principal limitante es que no se puede usar más de una anotación en una variable, por lo que 


# Swift Package Manager
Swift Package Manager es una herramienta para automatizar la distribución de código Swift y está integrado en el compilador Swift. Está en desarrollo temprano, pero experimental-annotation-swift admite su uso en plataformas compatibles.

Una vez que haya configurado su paquete Swift, agregar experimental-annotation-swift como dependencia es tan fácil como agregarlo al valor de dependencias de su Package.swift.

dependencies: [
    .package(url: "https://github.com/JavierSaldivarRubio/esperimental-annotation-swift", .upToNextMajor(from: "0.0.1"))
]
