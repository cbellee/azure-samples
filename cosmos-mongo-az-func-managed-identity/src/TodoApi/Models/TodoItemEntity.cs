using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace Todo.Api.Models
{
    public class TodoItemEntity
    {
        [BsonId]
        public ObjectId Id { get; set; }
        [BsonElement("title")]
        public string Title { get; set; }
        [BsonElement("iscomplete")]
        public bool IsComplete { get; set; }
    }
}