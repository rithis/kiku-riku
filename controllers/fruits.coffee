module.exports.getFruits = (Fruit, req, res) ->
  Fruit.find().exec()


module.exports.postFruits = (Fruit, req, res) ->
  Fruit.create(req.body)
  .then (fruit) ->
    res.send 201, fruit


module.exports.deleteFruits = (Fruit, req, res) ->
  Fruit.remove().exec()


module.exports.getFruit = (Fruit, req, res) ->
  Fruit.findOne(_id: req.params._id).exec()


module.exports.putFruit = (Fruit, req, res) ->
  Fruit.findOneAndUpdate(_id: req.params._id, req.body).exec()


module.exports.deleteFruit = (Fruit, req, res) ->
  Fruit.findOneAndRemove(_id: req.params._id).exec()
  .then (fruit) ->
    res.send if fruit then 200 else 404
