import ballerina/http;
import ballerina/time;
import ballerinax/mysql;
import ballerina/sql;

type User record {|
    @sql:Column { name: "id" }
    readonly int id;
    @sql:Column { name: "name" }
    string name;
    @sql:Column { name: "birth_date" }
    time:Date birthDate;
    @sql:Column { name: "mobile_number" }
    string mobileNumber;
|};

table<User> key(id) users = table [
    {id: 1, name: "Joe", birthDate: {year: 1990, month: 1, day: 1}, mobileNumber: "1234567890"}
];

type ErrorDetails record {
    string message;
    string details;
    time:Utc timestamp;
};

type UserNotFound record {|
    *http:NotFound;
    ErrorDetails body;
|};

type NewUser record {|
    string name;
    time:Date birthDate;
    string mobileNumber;
|};

type DatabseConfig record {|
    string host;
    string user;
    string password;
    string database;
    int port;
|};

configurable DatabseConfig dbConfig = ?;

mysql:Client socialMediaDB = check new(
    ...dbConfig 
);

service /social\-media on new http:Listener(9090) {

    // social-media/users
    resource function get users() returns User[]|error {
        stream<User, sql:Error?> userStream = socialMediaDB->query(`SELECT * FROM users`);
        return from var user in userStream select user;
    }

    resource function get users/[int id]() returns User|UserNotFound|error {

        User|sql:Error user = socialMediaDB->queryRow(`SELECT * FROM users WHERE id = ${id}`);
        if user is sql:NoRowsError {
            UserNotFound userNotFound = {
                body: {message: string `id: ${id}`, details: string `user/${id}`, timestamp: time:utcNow()}
            };
            return userNotFound;
        }
        return user;

        // User? user = users[id];
        // if user is () {
        //     UserNotFound userNotFound = {
        //         body: {message: string `id: ${id}`, details: string `user/${id}`, timestamp: time:utcNow()}
        //     };
        //     return userNotFound;
        // }
        // return user;
    }

    resource function post users(NewUser newUser) returns http:Created|error {

       transaction {

        _ = check socialMediaDB->execute(
            `INSERT INTO users(name, birth_date, mobile_number) 
             VALUES (${newUser.name}, ${newUser.birthDate}, ${newUser.mobileNumber})`
        );
         _ = check socialMediaDB->execute(
            `INSERT INTO followers(name, birth_date, mobile_number) 
             VALUES (${newUser.name}, ${newUser.birthDate}, ${newUser.mobileNumber})`);
        

        check commit;
       }




        // Insert user into users table

        return http:CREATED;
  };


 };
