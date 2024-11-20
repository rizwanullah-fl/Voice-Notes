// Parent class (Base class / Superclass)
class Vehicle {
  void startEngine() {
    print("Vehicle's engine started.");
  }

  void stopEngine() {
    print("Vehicle's engine stopped.");
  }
}

// Derived class (Child class / Subclass)
class Car extends Vehicle {
  void playMusic() {
    print("Playing music in the car.");
  }
}

// Derived class (Child class / Subclass)
class Bike extends Vehicle {
  void kickStart() {
    print("Bike started with a kick.");
  }
}
