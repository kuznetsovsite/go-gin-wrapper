package mongo

import (
	"github.com/hiromaily/go-gin-wrapper/pkg/configs"
	"github.com/hiromaily/golibs/db/mongodb"
	hrk "github.com/hiromaily/golibs/heroku"
)

func newMongoModel(conf *configs.Config) (*MongoModel, error) {
	c := conf.Mongo

	if conf.Environment == "heroku" {
		host, dbname, user, pass, port, err := hrk.GetMongoInfo("")
		if err == nil {
			c.Host = host
			c.DbName = dbname
			c.User = user
			c.Pass = pass
			c.Port = uint16(port)
		}
	}

	mi, err := mongodb.NewInstance(c.Host, c.DbName, c.User, c.Pass, c.Port)
	if err != nil {
		return nil, err
	}
	if c.DbName != "" {
		mi.GetDB(c.DbName)
	}

	return &MongoModel{
		DB: mi,
	}, nil
}