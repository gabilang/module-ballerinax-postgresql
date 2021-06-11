import ballerina/io;
import ballerinax/postgresql;
import ballerina/sql;

// The username , password and name of the PostgreSQL database
// You have to update these based on your setup.
string dbUsername = "postgres";
string dbPassword = "postgres";
string dbName = "postgres";

public function main() returns error? {
    // Runs the prerequisite setup for the example.
    check beforeExample();

    // Initializes the PostgresSQL client.
    postgresql:Client dbClient = check new (username = dbUsername,
                password = dbPassword, database = dbName);

    // Creates a parameterized query to invoke the procedure.
    string personName = "George";
    int personAge = 24;
    int personId = 1;
    sql:ParameterizedCallQuery sqlQuery =
                `CALL InsertStudent(${personId}, ${personName}, ${personAge})`;

    // Invokes the stored procedure `InsertStudent` with the `IN` parameters.
    sql:ProcedureCallResult retCall = check dbClient->call(sqlQuery);
    stream<record{}, error> resultStream = dbClient->query(`SELECT * FROM Student`);
    error? e = resultStream.forEach(function(record {} result) {
        io:println("Call stored procedure `InsertStudent`." +
                   "\nInserted data: ", result);
    });
    check retCall.close();

    // Initializes the `INOUT` parameters.
    int no = 1;
    int count = 0;
    sql:InOutParameter id = new(no);
    sql:InOutParameter totalCount = new(count);
    sql:ParameterizedCallQuery sqlQuery2 =
                        `CALL GetCount(${id}, ${totalCount})`;

    // The stored procedure with the `INOUT` parameters is invoked.
    sql:ProcedureCallResult retCall2 = check dbClient->call(sqlQuery2);
    io:println("Call stored procedure `GetCount`.");
    io:println("Age of the student with id '1' : ", id.get(int));
    io:println("Total student count: ", totalCount.get(int));
    check retCall2.close();

    // Closes the PostgresSQL client.
    check dbClient.close();
}

// Initializes the database as a prerequisite to the example.
function beforeExample() returns sql:Error? {
    // Initializes the PostgresSQL client.
    postgresql:Client dbClient = check new (username = dbUsername,
                password = dbPassword, database = dbName);

    // Creates a table in the database.
    sql:ExecutionResult result = check dbClient->execute(`DROP TABLE IF EXISTS Student`);
    result = check dbClient->execute(`CREATE TABLE Student
            (id bigint, age bigint, name text,
            PRIMARY KEY (id))`);

    // Creates the necessary stored procedures using the execute command.
    result = check dbClient->execute(`CREATE OR REPLACE PROCEDURE
        InsertStudent (IN id bigint, IN pName text, IN pAge bigint) language plpgsql as $$
        BEGIN INSERT INTO Student(id, age, name) VALUES (id, pAge, pName); END; $$ `);

    result = check dbClient->execute(`CREATE OR REPLACE PROCEDURE GetCount
        (INOUT pID bigint, INOUT totalCount bigint) language plpgsql as $$
        BEGIN
        SELECT age INTO pID FROM Student WHERE id = pID;
        SELECT COUNT(*) INTO totalCount FROM Student;
        END; $$ `);

    // Closes the PostgresSQL client.
    check dbClient.close();
}
