import ballerinax/mysql;
import ballerina/io;

configurable string dbHost = "localhost";
configurable int dbPort = 3306;
configurable string dbName = "social_media_database";
configurable string dbUser = "root";
configurable string dbPassword = "Castroaterice2day";

public final mysql:Client dbClient = check new(
    host = dbHost,
    port = dbPort,
    user = dbUser,
    password = dbPassword,
    database = dbName
);

public function testConnection() returns error? {
    stream<record {}, error?> result = dbClient->query(`SELECT 1`);
    check result.close();
    io:println("Database connection successful!");
}
