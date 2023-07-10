using Azure.Identity;
using Microsoft.Azure.Cosmos;
using Microsoft.Azure.Functions.Extensions.DependencyInjection;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Todo.Api;
using Todo.Api.Helpers;
using Todo.Api.Helpers.Interfaces;
using MongoDB.Driver;
using Azure.ResourceManager.CosmosDB.Models;
using Azure.ResourceManager.CosmosDB;
using Azure.ResourceManager;
using Azure.Core;
using Azure.ResourceManager.Resources;

[assembly: FunctionsStartup(typeof(Startup))]
namespace Todo.Api
{
    public class Startup : FunctionsStartup
    {
        public override void Configure(IFunctionsHostBuilder builder)
        {
            var config = new ConfigurationBuilder()
                .SetBasePath(Directory.GetCurrentDirectory())
                .AddJsonFile("local.settings.json", optional: true, reloadOnChange: true)
                .AddEnvironmentVariables()
                .Build();

            builder.Services.AddLogging();
            builder.Services.AddSingleton<IConfiguration>(config);
            builder.Services.AddSingleton(sp =>
            {
                IConfiguration config = sp.GetRequiredService<IConfiguration>();

                ArmClient client = new ArmClient(new DefaultAzureCredential());
                ResourceIdentifier rid = Azure.ResourceManager.CosmosDB.CosmosDBAccountResource.CreateResourceIdentifier(config["subscriptionId"], config["resourceGroup"], config["cosmosDbAccount"]);
                CosmosDBAccountKeyList keys = client.GetCosmosDBAccountResource(rid).GetKeys();
                String mongoConnection = $"mongodb://{config["cosmosDbAccount"]}:{keys.PrimaryMasterKey}@{config["cosmosDbAccount"]}.{config["cosmosMongoSuffix"]}:{config["cosmosDbPort"]}/?ssl=true&replicaSet=globaldb&retrywrites=false&maxIdleTimeMS=120000&appName=@{config["cosmosDbAccount"]}@";

                MongoClient mongoClient = new MongoClient(mongoConnection);
                return mongoClient;
            });
            builder.Services.AddSingleton<ITodoRepository, TodoRepository>();
        }
    }
}