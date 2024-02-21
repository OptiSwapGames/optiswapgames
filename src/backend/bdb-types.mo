import List "mo:base/List";

module {
  public type InputCommandTypes = {
    #Thrust;
    #Fire;
    #None;
  };

  public type Result = {
    #Ok;
    #Err;
  };

  public type Vector = {
    x: Float;
    y: Float;
  };

  public type InputCommand = {
    commandType: InputCommandTypes;
    vector: Vector;
    player: Nat;
  };

  public type Position = Vector;
  public type Velocity = Vector;
  public type Acceleration = Vector;

  public type InertialState = {
    position: Position;
    velocity: Velocity;
    acceleration: Acceleration;
    mass: Nat;
  };

  public type PhysicalPresence = {
    inertialState: InertialState;
    radius: Nat;
  };

  public type GameObjectType = {
    #Ship;
    #Bomb;
  };

  public type GameObject = {
    t: GameObjectType;
    physicalPresence : PhysicalPresence;
    cleanup: Bool;
    id: Nat;
  };

  public type GameStatus = {
    #Nonexistent;
    #Active;
    #Complete;
    #Finalized;
  };

  public type QueueEntry = {
    player : Principal;
    amount : Nat;
    name : Text;
  };
  
  public type BDBView = {
    status: GameStatus;
    objects: ([GameObject]);
    tick: Nat;
    dataKeys: ([Text]);
    dataValues: ([Nat]);
  };
}
