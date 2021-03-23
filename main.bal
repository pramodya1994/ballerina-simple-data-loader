import ballerina/log;
import ballerinax/mysql;
import ballerina/sql;
import ballerina/io;

configurable string csvPath = ?;
configurable string dbHost = ?;
configurable string dbUser = ?;
configurable string dbPassword = ?;
configurable string dbName = ?;

public function main() returns error? {
    stream<string[], io:Error>|error|() readCsvResult = readCsv(csvPath);
    if readCsvResult is stream<string[], io:Error> {
        Contact[] contacts = getContacts(readCsvResult);

        // Select salesforce contacts
        SalesforceContact[] sfContacts = from var contact in contacts 
            where contact.description == "Salesforce contact"
            order by contact.firstName descending
            select {
                name: contact.firstName + " " + contact.lastName,
                title: contact.title,
                phone: contact.phone,
                email: contact.email
            };

        foreach var contact in sfContacts {
            io:println(contact);
        }  

        // Add salesforce contacts to MySQL DB
        mysql:Client|sql:Error mysqlClient = new (dbHost, dbUser, dbPassword, dbName, 3306);
        if (mysqlClient is sql:Error) {
            log:printError("Database connection failed", 'error = mysqlClient);
        } else {
            sql:ParameterizedQuery[] insertQuery = 
            from var contact in sfContacts
            select `INSERT INTO contacts(name, title, phone, email) VALUES 
                (${contact.name}, ${contact.title}, ${contact.phone}, ${contact.email})`;

            sql:ExecutionResult[]|sql:Error batchExecute = mysqlClient->batchExecute(insertQuery);

            if (batchExecute is sql:ExecutionResult[]) {
                int[] generatedIds = [];
                foreach var summary in batchExecute {
                    generatedIds.push(<int>summary.lastInsertId);
                }
                io:println("\nInsert succesful, generetaed IDs:", generatedIds, "\n");
            }
        }

        
    } else {
        if readCsvResult is error {
            log:printError("Reading csv failed", 'error = readCsvResult);   
        } else {
            log:printError("Reading csv failed");   
        }
    }
}

function readCsv(string path) returns stream<string[], io:Error>|error? {
    stream<string[], io:Error> readCsv = check io:fileReadCsvAsStream(path);
    return readCsv;
}

function getContacts(stream<string[], io:Error> readCsv) returns Contact[] {
    Contact[] contacts = [];
    error? forEach = readCsv.forEach(function(string[] row){
        Contact contact = getContact(row);
        contacts[contacts.length()] = contact;
    });
    return contacts;
}
