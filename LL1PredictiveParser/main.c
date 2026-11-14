#include <stdio.h>
#include <string.h>

#define MAX 100

char stack[MAX];
int top = -1;

void push(char c)
{
    if (top < MAX - 1)
        stack[++top] = c;
}

char pop()
{
    if (top >= 0)
        return stack[top--];

    return '\0';
}

char peek()
{
    if (top >= 0)
        return stack[top];

    return '\0';
}

int isTerminal(char c)
{
    return c == 'a' ||
           c == 'b' ||
           c == '+' ||
           c == '*' ||
           c == '$';
}

void displayStack()
{
    int i;

    for (i = 0; i <= top; i++)
        printf("%c", stack[i]);
}

void displayInput(char input[], int ip)
{
    int i;

    for (i = ip; input[i] != '\0'; i++)
        printf("%c", input[i]);
}

int getProduction(char nonTerminal, char terminal)
{
    // E -> TE'
    if (nonTerminal == 'E')
    {
        if (terminal == 'a' || terminal == 'b')
            return 1;
    }

    // E' -> +TE' | epsilon
    else if (nonTerminal == 'e')
    {
        if (terminal == '+')
            return 2;

        if (terminal == '$')
            return 3;
    }

    // T -> FT'
    else if (nonTerminal == 'T')
    {
        if (terminal == 'a' || terminal == 'b')
            return 4;
    }

    // T' -> FT' | epsilon
    else if (nonTerminal == 't')
    {
        if (terminal == 'a' || terminal == 'b')
            return 5;

        if (terminal == '+' || terminal == '$')
            return 6;
    }

    // F -> aF' | bF'
    else if (nonTerminal == 'F')
    {
        if (terminal == 'a')
            return 7;

        if (terminal == 'b')
            return 8;
    }

    // F' -> *F' | epsilon
    else if (nonTerminal == 'f')
    {
        if (terminal == '*')
            return 9;

        if (terminal == 'a' ||
            terminal == 'b' ||
            terminal == '+' ||
            terminal == '$')
            return 10;
    }

    return -1;
}

void printProduction(int production)
{
    if (production == 1)
        printf("E -> TE'");

    else if (production == 2)
        printf("E' -> +TE'");

    else if (production == 3)
        printf("E' -> epsilon");

    else if (production == 4)
        printf("T -> FT'");

    else if (production == 5)
        printf("T' -> FT'");

    else if (production == 6)
        printf("T' -> epsilon");

    else if (production == 7)
        printf("F -> aF'");

    else if (production == 8)
        printf("F -> bF'");

    else if (production == 9)
        printf("F' -> *F'");

    else if (production == 10)
        printf("F' -> epsilon");
}

void applyProduction(int production)
{
    // E -> TE'
    if (production == 1)
    {
        push('e');
        push('T');
    }

    // E' -> +TE'
    else if (production == 2)
    {
        push('e');
        push('T');
        push('+');
    }

    // E' -> epsilon
    else if (production == 3)
    {
    }

    // T -> FT'
    else if (production == 4)
    {
        push('t');
        push('F');
    }

    // T' -> FT'
    else if (production == 5)
    {
        push('t');
        push('F');
    }

    // T' -> epsilon
    else if (production == 6)
    {
    }

    // F -> aF'
    else if (production == 7)
    {
        push('f');
        push('a');
    }

    // F -> bF'
    else if (production == 8)
    {
        push('f');
        push('b');
    }

    // F' -> *F'
    else if (production == 9)
    {
        push('f');
        push('*');
    }

    // F' -> epsilon
    else if (production == 10)
    {
    }
}

int main()
{
    char input[MAX];
    int ip = 0;
    int step = 1;
    int valid = 1;
    int accepted = 0;

    printf("Enter input string ending with $: ");
    scanf("%99s", input);

    // Check whether input ends with $
    if (strlen(input) == 0 || input[strlen(input) - 1] != '$')
    {
        printf("\nError: Input must end with $.\n");
        return 0;
    }

    // Initialize stack
    top = -1;

    // Push end marker and start symbol
    push('$');
    push('E');

    printf("\n");
    printf("%-6s %-20s %-20s %s\n",
           "Step", "Stack", "Input", "Action");

    printf("---------------------------------------------------------------\n");

    while (top >= 0)
    {
        char X = peek();
        char currentInput = input[ip];

        printf("%-6d ", step++);

        // Display stack
        displayStack();
        printf("%*s", 20 - (top + 1), "");

        // Display remaining input
        displayInput(input, ip);
        printf("%*s", 20 - (int)strlen(input + ip), "");

        // Accept when both stack and input contain $
        if (X == '$' && currentInput == '$')
        {
            printf("Accept\n");
            accepted = 1;
            break;
        }

        // Match terminal
        if (isTerminal(X))
        {
            if (X == currentInput)
            {
                pop();
                ip++;

                printf("Match '%c'", X);
            }
            else
            {
                printf("Error: expected '%c', found '%c'",
                       X, currentInput);

                valid = 0;
                printf("\n");
                break;
            }
        }

        // Process non-terminal
        else
        {
            int production = getProduction(X, currentInput);

            if (production == -1)
            {
                printf("Error: no production for ");

                if (X == 'e')
                    printf("E'");
                else if (X == 't')
                    printf("T'");
                else if (X == 'f')
                    printf("F'");
                else
                    printf("%c", X);

                printf(" with input '%c'", currentInput);

                valid = 0;
                printf("\n");
                break;
            }

            pop();

            printProduction(production);
            applyProduction(production);
        }

        printf("\n");
    }

    printf("---------------------------------------------------------------\n");

    // Print final result
    if (accepted && valid)
    {
        printf("\nSuccessfully Parsed (Valid)\n");
    }
    else
    {
        printf("\nRejected (Syntax Error)\n");
    }

    return 0;
}
