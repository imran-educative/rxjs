import { interval } from 'rxjs';
import { tap, mapTo } from 'rxjs/operators';
import { animationFrame } from 'rxjs/internal/scheduler/animationFrame';

import { config } from './config';
import { GameState } from './gameState';

// Game loop stuff
import { updateStars, renderStars } from './stars';
import { updatePlayer, renderPlayer } from './player';
import { updateEnemies, renderEnemies } from './enemy';
import { renderLasers } from './lasers';
import { checkCollision, renderExplosions } from './collisions';
import { renderGameOver, resetGame } from './gameOver';

/*
ART:
player spaceship: https://opengameart.org/content/24x24-48x48-spaceships
aliens: https://opengameart.org/content/alien-spaceship-invasion
explosion: https://opengameart.org/content/simple-explosion-bleeds-game-art
*/

// START: canvas-init
let canvas = <HTMLCanvasElement>document.querySelector('canvas');
export let ctx = canvas.getContext('2d'); // <callout id="co.canvas.context"/>
canvas.width = config.canvas.width; // <callout id="co.canvas.widthHeight"/>
canvas.height = config.canvas.height;
// END: canvas-init

// START: clear-canvas
function clearCanvas() {
  ctx.fillStyle = '#000';
  ctx.fillRect(0, 0, canvas.width, canvas.height);
}
// END: clear-canvas

/* todo:
- different animation sequence for enemy
*/

let gameState = new GameState();

interval(17, animationFrame)
.pipe(
  mapTo(gameState),
  resetGame,
  updateStars,
  updatePlayer,
  updateEnemies,
  checkCollision,
  // Use tap for side effects, ensure render does not mutate state
  tap(clearCanvas),
  tap(renderStars),
  tap(renderPlayer),
  tap(renderLasers),
  tap(renderEnemies),
  tap(renderExplosions),
  tap(renderGameOver)
)
.subscribe((newGameState: GameState) => {
  Object.assign(gameState, newGameState);
});
