import { Router, Request, Response } from "express";
import db from "../db";
import { NewUser, users } from "../db/schema";
import { eq } from "drizzle-orm";
import bcryptjs from "bcryptjs";
import jwt from "jsonwebtoken";
import { auth, AuthRequest } from "../middleware/auth";
const authRouter = Router();
interface SignUpBody {
    name: string;
    email: string;
    password: string;
}
interface LoginBody {
    email: string;
    password: string;
}
authRouter.post("/signup", async (req: Request<{}, {}, SignUpBody>, res: Response) => {
    try {
        const { name, email, password } = req.body;

        const existingUser = await db.select().
            from(users)
            .where(eq(users.email, email));
        // if user is alredy avalable 
        if (existingUser.length) {
            res.status(400)
                .json({ msg: "User with the same name alredy exist" });
            return;
        }

        //hashed Password
        const hashPassword = await bcryptjs.hash(password, 8);

        //Craete New User

        const newUser: NewUser = {
            name,
            email,
            password: hashPassword,
        }

        const [user] = await db.insert(users).values(newUser).returning();
        res.status(201).json(user);


    }
    catch (e) {
        res.status(500).json({ error: e });
    }
});
authRouter.post("/login", async (req: Request<{}, {}, LoginBody>, res: Response) => {
    try {
        const { email, password } = req.body;

        const [existingUser] = await db.select().
            from(users)
            .where(eq(users.email, email));
        // if user is not  avalable 
        if (!existingUser) {
            res.status(400)
                .json({ msg: "User with the same name does not exists" });
            return;
        }

        //is Match Password
        const isMatched = await bcryptjs.compare(password, existingUser.password);

        if (!isMatched) {
            res.status(400).json({ msg: "Incorrect password" });
        }

        const token = jwt.sign({ id: existingUser.id }, "passwordKey");

        res.json({ token, ...existingUser });


    }
    catch (e) {
        res.status(500).json({ error: e });
    }
});

authRouter.post("/tokenIsValid", async (req, res) => {
    try {

        // Get the jeder

        const token = req.header('x-auth-token');

        if (!token) {
            res.json(false);
            return;
        }

        // verify token
        const verifyed = jwt.verify(token, "passwordKey");
        if (!verifyed) {
            res.json(false);

            return;
        }

        // get user data if token is valid
        const verifyedToken = verifyed as { id: string };

        const [user] = await db.select()
            .from(users)
            .where(eq(users.id, verifyedToken.id));
        if (!user) {
            res.json(false);
            return;
        }

        res.json(true);

    } catch (e) {
        res.status(500).json({ error: e });

    }
});
authRouter.get("/", auth, async (req: AuthRequest, res) => {

    try {
        if (!req.user) {
            res.status(401).json({ msg: "User not found" });
            return;

        }
        const [user] = await db.select().from(users).where(eq(users.id, req.user));
        res.json({ ...user, token: req.token });

    } catch (e) {
        res.status(500).json({ error: e });


    }
});
export default authRouter;