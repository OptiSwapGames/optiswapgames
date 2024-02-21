import * as React from 'react';
import Lobby from "./Lobby"
import BulldogBlast from "./BulldogBlast"

const App = () => {
    const [context, setContext] = React.useState("lobby");
    const [gameID, setGameID] = React.useState(null);
    const [playerID, setPlayerID] = React.useState(null);

    const inputRef = React.useRef();

    const handleGameStart = (gameID, playerID) => {
      setGameID(gameID);
      setPlayerID(playerID);
      setContext("game");
    }

    const handleGameEnd = async () => {
      setPlayerID(null)
      setGameID(null)
      setContext("lobby")
    }

    return (
      <div>
        {(context == "lobby") ?
          <Lobby handleGameStart = { handleGameStart }/>  :
          <BulldogBlast gameID = { gameID }
                        playerID = { playerID }
                        handleGameEnd = { handleGameEnd } />}
      </div>
    );
}

export default App;
