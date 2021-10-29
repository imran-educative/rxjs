'use strict';

let express = require('express');
let router = express.Router();

/* GET home page. */
router.get('/creatingObservables', function (req, res, next) {
  res.render('creatingObservables', { title: 'Creating Observables' });
});

module.exports = router;
