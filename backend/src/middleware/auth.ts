import { NextFunction, Request, Response } from "express";
import { UUID } from "crypto";
import jwt from "jsonwebtoken";
import db from "../db";
import { users } from "../db/schema";
import { eq } from "drizzle-orm";
export interface AuthRequest extends Request {
    user?: UUID;
    token?: string;
}
export const auth = async (req: AuthRequest, res: Response, next: NextFunction) => {
    try {

        // Get the jeder

        const token = req.header('x-auth-token');

        if (!token) {
            res.status(401).json({ msg: "no Auth token, acces deined" });
            return;
        }

        // verify token
        const verifyed = jwt.verify(token, "passwordKey");
        if (!verifyed) {
            res.status(401).json({ msg: "json veifiction failded" });

            return;
        }

        // get user data if token is valid
        const verifyedToken = verifyed as { id: UUID };

        const [user] = await db.select()
            .from(users)
            .where(eq(users.id, verifyedToken.id));
        if (!user) {
            res.status(401).json({ msg: "User not found" });
            return;
        }
        req.user = verifyedToken.id;
        req.token = token;
        next();

    } catch (e) {
        res.status(500).json({ error: e });

    }
}